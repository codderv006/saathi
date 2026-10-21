import 'dart:async';

import 'package:flutter/foundation.dart';

import 'workflow.dart';
import 'workflow_engine.dart';
import 'workflow_store.dart';

sealed class ApplyOutcome {
  const ApplyOutcome();
}

class Applied extends ApplyOutcome {
  const Applied(this.session, this.effect);
  final WorkflowSession session;
  final Effect effect;
  @override
  String toString() => 'Applied(${effect.name}, ${session.currentStepId})';
}

class Refused extends ApplyOutcome {
  const Refused(this.reason);
  final RejectReason reason;
  @override
  String toString() => 'Refused(${reason.name})';
}

class SaveFailed extends ApplyOutcome {
  const SaveFailed(this.error);
  final Object error;
  @override
  String toString() => 'SaveFailed($error)';
}

/// A voice-originated request that needs the user's explicit on-screen confirmation.
class NeedsUserConfirmation extends ApplyOutcome {
  const NeedsUserConfirmation(this.stepId);
  final String stepId;
}

class InvalidRequest extends ApplyOutcome {
  const InvalidRequest(this.message);
  final String message;
  @override
  String toString() => 'InvalidRequest($message)';
}

enum RestoreResult { none, restored, incompatible, failed }

/// Owns the one active guide session (any workflow). Commands run one at a time;
/// in-memory state only moves after the store accepted the write, so a failed save
/// never advances the workflow.
class WorkflowController extends ChangeNotifier {
  WorkflowController({
    required this.store,
    required WorkflowDefinition? Function(String id) findDefinition,
    DateTime Function()? clock,
  }) : _find = findDefinition,
       _clock = clock ?? DateTime.now;

  final WorkflowStore store;
  final WorkflowDefinition? Function(String id) _find;
  final DateTime Function() _clock;
  Future<void> _tail = Future.value();
  WorkflowEngine? _engine;

  WorkflowSession? _session;
  WorkflowSession? get session => _session;

  /// Set when the voice agent reported "done" for this step; cleared by the user.
  String? _pendingVoiceConfirmation;
  String? get pendingVoiceConfirmation => _pendingVoiceConfirmation;

  /// Definition of the current session's workflow, if any.
  WorkflowDefinition? get definition => _engine?.definition;

  WorkflowStep? get currentStep => _session == null
      ? null
      : _engine?.definition.stepById(_session!.currentStepId);

  Future<ApplyOutcome> startNew({
    required WorkflowDefinition definition,
    required String sessionId,
    required String installationId,
    required String language,
    String? userId,
  }) => _serialized(() async {
    final engine = WorkflowEngine(definition);
    final fresh = engine.start(
      sessionId: sessionId,
      installationId: installationId,
      language: language,
      userId: userId,
      now: _clock(),
    );
    try {
      await store.save(fresh, expectedRevision: 0);
    } catch (e) {
      return SaveFailed(e);
    }
    _pendingVoiceConfirmation = null;
    _engine = engine;
    _set(fresh);
    return Applied(fresh, Effect.unchanged);
  });

  Future<ApplyOutcome> apply(WorkflowCommand command) => _serialized(() async {
    final current = _session;
    final engine = _engine;
    if (current == null || engine == null) {
      return const Refused(RejectReason.sessionClosed);
    }
    final result = engine.apply(current, command, _clock());
    switch (result) {
      case Rejected(:final reason):
        return Refused(reason);
      case Accepted(:final session, :final effect, :final changed):
        if (changed) {
          try {
            await store.save(session, expectedRevision: current.revision);
          } catch (e) {
            return SaveFailed(e);
          }
          _pendingVoiceConfirmation = null;
          _set(session);
        }
        return Applied(session, effect);
    }
  });

  /// Untrusted requests from the voice agent (tool calls). Strict whitelist; the
  /// agent can ask, never set state. "Done" only raises an on-screen confirmation.
  Future<ApplyOutcome> applyVoiceRequest(Map<String, Object?> payload) async {
    const allowed = {'action', 'step_id'};
    if (payload.keys.any((k) => !allowed.contains(k))) {
      return const InvalidRequest('unexpected fields');
    }
    final stepId = payload['step_id'];
    switch (payload['action']) {
      case 'request_repeat_instruction':
        return apply(const RepeatInstruction());
      case 'request_help':
        return apply(const RequestHelp());
      case 'request_simpler':
        return apply(const ExplainSimpler());
      case 'request_previous_step' when stepId is String:
        return apply(GoBack(stepId));
      case 'request_step_confirmation' when stepId is String:
        final current = _session;
        if (current == null || !current.isOpen) {
          return const Refused(RejectReason.sessionClosed);
        }
        if (stepId != current.currentStepId) {
          return const Refused(RejectReason.notCurrentStep);
        }
        _pendingVoiceConfirmation = stepId;
        notifyListeners();
        return NeedsUserConfirmation(stepId);
      default:
        // Includes any attempt to declare completion: outcomes come only from the
        // user's own on-screen answer.
        return InvalidRequest('action not allowed: ${payload['action']}');
    }
  }

  void dismissVoiceConfirmation() {
    _pendingVoiceConfirmation = null;
    notifyListeners();
  }

  Future<RestoreResult> restore() => _serialized(() async {
    final WorkflowSession? loaded;
    try {
      loaded = await store.loadActive();
    } catch (_) {
      return RestoreResult.failed;
    }
    if (loaded == null) return RestoreResult.none;
    final def = _find(loaded.workflowId);
    if (def == null) return RestoreResult.incompatible; // guide removed/renamed
    final engine = WorkflowEngine(def);
    if (!engine.isCompatible(loaded)) return RestoreResult.incompatible;
    _engine = engine;
    _set(loaded);
    return RestoreResult.restored;
  });

  Future<void> clear() => _serialized(() async {
    await store.clear();
    _pendingVoiceConfirmation = null;
    _engine = null;
    _set(null);
  });

  void _set(WorkflowSession? s) {
    _session = s;
    notifyListeners();
  }

  Future<T> _serialized<T>(Future<T> Function() task) {
    final result = _tail.then((_) => task());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }
}
