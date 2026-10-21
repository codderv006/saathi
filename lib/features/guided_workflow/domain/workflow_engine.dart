import 'workflow.dart';

enum RejectReason {
  notCurrentStep,
  notAllowedOnThisStep,
  atFirstStep,
  sessionClosed,
  sessionPaused,
  workflowMismatch,
  unknownStep,
}

/// What an accepted command did, so the UI and voice layer can respond.
enum Effect {
  advanced,
  wentBack,
  repeated,
  help,
  simpler,
  paused,
  resumed,
  completed,
  endedWithoutSuccess,
  unchanged,
}

sealed class EngineResult {
  const EngineResult();
}

class Accepted extends EngineResult {
  const Accepted(this.session, this.effect);
  final WorkflowSession session;
  final Effect effect;
  bool get changed => switch (effect) {
    Effect.repeated ||
    Effect.help ||
    Effect.simpler ||
    Effect.unchanged => false,
    _ => true,
  };
}

class Rejected extends EngineResult {
  const Rejected(this.reason);
  final RejectReason reason;
  @override
  String toString() => 'Rejected(${reason.name})';
}

/// Pure transition function: no I/O, never mutates its input. The engine — not the
/// voice model — decides the current step.
class WorkflowEngine {
  const WorkflowEngine(this.definition);

  final WorkflowDefinition definition;

  WorkflowSession start({
    required String sessionId,
    required String installationId,
    required String language,
    required DateTime now,
    String? userId,
  }) => WorkflowSession(
    id: sessionId,
    installationId: installationId,
    userId: userId,
    workflowId: definition.id,
    currentStepId: definition.initialStepId,
    status: SessionStatus.active,
    language: language,
    history: const [],
    revision: 1,
    createdAt: now,
    updatedAt: now,
  );

  /// Null if [session] can't be resumed with this definition (e.g. the guide changed).
  bool isCompatible(WorkflowSession session) =>
      session.workflowId == definition.id &&
      definition.indexOf(session.currentStepId) >= 0;

  EngineResult apply(WorkflowSession s, WorkflowCommand command, DateTime now) {
    if (s.workflowId != definition.id) {
      return const Rejected(RejectReason.workflowMismatch);
    }
    final step = definition.stepById(s.currentStepId);
    if (step == null) return const Rejected(RejectReason.unknownStep);

    // Read-only requests are always fine and never move the step.
    switch (command) {
      case RepeatInstruction():
        return Accepted(s, Effect.repeated);
      case RequestHelp():
        return Accepted(s, Effect.help);
      case ExplainSimpler():
        return Accepted(s, Effect.simpler);
      default:
        break;
    }

    if (!s.isOpen) return const Rejected(RejectReason.sessionClosed);

    WorkflowSession next(
      SessionStatus status, {
      String? stepId,
      Outcome? outcome,
      ProgressEvent? event,
    }) => s.copyWith(
      status: status,
      currentStepId: stepId,
      outcome: outcome,
      history: event == null ? null : [...s.history, event],
      revision: s.revision + 1,
      updatedAt: now,
    );

    switch (command) {
      case Pause():
        if (s.status == SessionStatus.paused) {
          return Accepted(s, Effect.unchanged);
        }
        return Accepted(next(SessionStatus.paused), Effect.paused);

      case Resume():
        if (s.status == SessionStatus.active) {
          return Accepted(s, Effect.unchanged);
        }
        return Accepted(next(SessionStatus.active), Effect.resumed);

      case _ when s.status == SessionStatus.paused:
        return const Rejected(RejectReason.sessionPaused);

      case ConfirmStep(:final stepId):
        if (stepId != s.currentStepId) {
          return const Rejected(RejectReason.notCurrentStep);
        }
        if (step.kind != StepKind.instruction) {
          return const Rejected(RejectReason.notAllowedOnThisStep);
        }
        final nextId = definition.nextStepId(stepId);
        if (nextId == null) {
          // A workflow without an outcome step finishes on its last confirmation.
          return Accepted(
            next(
              SessionStatus.completed,
              outcome: Outcome.succeeded,
              event: ProgressEvent(stepId, ProgressEventKind.confirmed, now),
            ),
            Effect.completed,
          );
        }
        return Accepted(
          next(
            SessionStatus.active,
            stepId: nextId,
            event: ProgressEvent(stepId, ProgressEventKind.confirmed, now),
          ),
          Effect.advanced,
        );

      case GoBack(:final fromStepId):
        if (fromStepId != s.currentStepId) {
          return const Rejected(RejectReason.notCurrentStep);
        }
        final previousId = definition.previousStepId(fromStepId);
        if (previousId == null) return const Rejected(RejectReason.atFirstStep);
        return Accepted(
          next(
            SessionStatus.active,
            stepId: previousId,
            event: ProgressEvent(fromStepId, ProgressEventKind.wentBack, now),
          ),
          Effect.wentBack,
        );

      case ReportOutcome(:final stepId, :final outcome):
        if (stepId != s.currentStepId) {
          return const Rejected(RejectReason.notCurrentStep);
        }
        if (step.kind != StepKind.outcome) {
          return const Rejected(RejectReason.notAllowedOnThisStep);
        }
        final success = outcome == Outcome.succeeded;
        return Accepted(
          next(
            success ? SessionStatus.completed : SessionStatus.ended,
            outcome: outcome,
            event: ProgressEvent(stepId, ProgressEventKind.confirmed, now),
          ),
          success ? Effect.completed : Effect.endedWithoutSuccess,
        );

      case RepeatInstruction() || RequestHelp() || ExplainSimpler():
        throw StateError('handled above');
    }
  }
}
