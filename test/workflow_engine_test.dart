import 'package:flutter_test/flutter_test.dart';
import 'package:saathi_poc/features/guided_workflow/data/ride_workflow.dart';
import 'package:saathi_poc/features/guided_workflow/data/workflow_registry.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow_engine.dart';

void main() {
  final olaWorkflow = WorkflowRegistry.find(
    RideApp.ola.workflowId(fromInstall: false),
  )!;
  final engine = WorkflowEngine(olaWorkflow);
  final t0 = DateTime.utc(2026, 10, 21);
  final ids = olaWorkflow.steps.map((s) => s.id).toList();
  final outcomeStep = ids.last;

  WorkflowSession fresh() => engine.start(
    sessionId: 's1',
    installationId: 'i1',
    language: 'en',
    now: t0,
  );

  WorkflowSession at(int index) {
    var s = fresh();
    for (var i = 0; i < index; i++) {
      s = (engine.apply(s, ConfirmStep(ids[i]), t0) as Accepted).session;
    }
    return s;
  }

  EngineResult run(WorkflowSession s, WorkflowCommand c) =>
      engine.apply(s, c, t0);

  test('Ola, Uber and Rapido guides are registered and name their app', () {
    for (final app in RideApp.values) {
      final def = WorkflowRegistry.find(app.workflowId(fromInstall: false))!;
      expect(RideApp.fromWorkflowId(def.id), app);
      expect(def.steps.map((s) => s.id), ids, reason: 'same logical steps');
      expect(def.steps.first.instruction.of('en'), contains(app.displayName));
      expect(def.steps.first.instruction.of('mr'), contains(app.displayName));
      expect(
        def.steps.first.screenshot!.asset,
        startsWith('assets/workflows/${app.name}/'),
      );
    }
  });

  test('fresh-install guides start at Play Store and protect the OTP', () {
    for (final app in RideApp.values) {
      final def = WorkflowRegistry.find(app.workflowId(fromInstall: true))!;
      final stepIds = def.steps.map((s) => s.id).toList();
      expect(stepIds.first, 'install_app');
      expect(stepIds.sublist(0, 6), [
        'install_app',
        'open_app',
        'enter_phone',
        'enter_otp',
        'profile_details',
        'allow_location',
      ]);
      expect(stepIds.sublist(6), ids.sublist(1), reason: 'then booking');
      expect(def.stepById('enter_otp')!.sensitivity, Sensitivity.secretCode);
      expect(def.stepById('check_fare')!.sensitivity, Sensitivity.money);
      expect(RideApp.fromWorkflowId(def.id), app);
    }
  });

  test('Ola definition is well formed', () {
    expect(ids.toSet(), hasLength(ids.length));
    expect(olaWorkflow.steps.last.kind, StepKind.outcome);
    expect(WorkflowRegistry.find(olaWorkflow.id), same(olaWorkflow));
    expect(WorkflowRegistry.find('whatsapp'), isNull);
    for (final step in olaWorkflow.steps) {
      for (final lang in ['en', 'mr']) {
        expect(step.title.of(lang), isNotEmpty);
        expect(step.instruction.of(lang), isNotEmpty);
        expect(step.simplerInstruction.of(lang), isNotEmpty);
      }
    }
  });

  test('starts at the initial step, active, revision 1', () {
    final s = fresh();
    expect(s.currentStepId, olaWorkflow.initialStepId);
    expect(s.status, SessionStatus.active);
    expect(s.revision, 1);
    expect(s.history, isEmpty);
  });

  test('explicit confirmation advances exactly one step and is recorded', () {
    final r = run(fresh(), ConfirmStep(ids[0])) as Accepted;
    expect(r.effect, Effect.advanced);
    expect(r.session.currentStepId, ids[1]);
    expect(r.session.revision, 2);
    expect(r.session.confirmedAt(ids[0]), t0);
  });

  test('confirming a step that is not current is rejected (no skipping)', () {
    expect(
      (run(fresh(), ConfirmStep(ids[3])) as Rejected).reason,
      RejectReason.notCurrentStep,
    );
  });

  test('duplicate confirmation does not skip a step', () {
    final once = at(1);
    expect(run(once, ConfirmStep(ids[0])), isA<Rejected>());
  });

  test('repeat, help and simpler never change state', () {
    final s = at(2);
    for (final c in const [
      RepeatInstruction(),
      RequestHelp(),
      ExplainSimpler(),
    ]) {
      final r = run(s, c) as Accepted;
      expect(r.changed, isFalse);
      expect(identical(r.session, s), isTrue);
    }
  });

  test('back goes one step, keeps confirmation history', () {
    final s = at(2);
    final back = (run(s, GoBack(ids[2])) as Accepted).session;
    expect(back.currentStepId, ids[1]);
    expect(back.confirmedAt(ids[1]), isNotNull, reason: 'history kept');
    expect(back.history.last.kind, ProgressEventKind.wentBack);
    expect(run(back, GoBack(ids[2])), isA<Rejected>(), reason: 'stale back');
    expect(
      (run(fresh(), GoBack(ids[0])) as Rejected).reason,
      RejectReason.atFirstStep,
    );
  });

  test(
    'outcome step cannot be "confirmed"; only an explicit outcome ends it',
    () {
      final s = at(ids.length - 1);
      expect(s.currentStepId, outcomeStep);
      expect(
        s.status,
        SessionStatus.active,
        reason: 'reaching last step ≠ done',
      );
      expect(
        (run(s, ConfirmStep(outcomeStep)) as Rejected).reason,
        RejectReason.notAllowedOnThisStep,
      );
    },
  );

  test(
    'reported success completes; reported non-success ends without success',
    () {
      final s = at(ids.length - 1);
      final ok =
          run(s, ReportOutcome(outcomeStep, Outcome.succeeded)) as Accepted;
      expect(ok.effect, Effect.completed);
      expect(ok.session.status, SessionStatus.completed);
      expect(ok.session.outcome, Outcome.succeeded);

      final no =
          run(s, ReportOutcome(outcomeStep, Outcome.notCompleted)) as Accepted;
      expect(no.effect, Effect.endedWithoutSuccess);
      expect(no.session.status, SessionStatus.ended);
      expect(no.session.outcome, Outcome.notCompleted);
    },
  );

  test('outcome cannot be reported before the outcome step', () {
    expect(
      (run(fresh(), ReportOutcome(ids[0], Outcome.succeeded)) as Rejected)
          .reason,
      RejectReason.notAllowedOnThisStep,
    );
  });

  test('closed sessions reject changes (no accidental resume)', () {
    final done =
        (run(at(ids.length - 1), ReportOutcome(outcomeStep, Outcome.succeeded))
                as Accepted)
            .session;
    for (final c in [
      ConfirmStep(outcomeStep),
      GoBack(outcomeStep),
      const Resume(),
      const Pause(),
    ]) {
      expect((run(done, c) as Rejected).reason, RejectReason.sessionClosed);
    }
    expect(run(done, const RepeatInstruction()), isA<Accepted>());
  });

  test('paused sessions must resume before progressing', () {
    final paused = (run(at(1), const Pause()) as Accepted).session;
    expect(paused.status, SessionStatus.paused);
    expect(
      (run(paused, ConfirmStep(ids[1])) as Rejected).reason,
      RejectReason.sessionPaused,
    );
    final resumed = (run(paused, const Resume()) as Accepted).session;
    expect(resumed.status, SessionStatus.active);
    expect(resumed.currentStepId, ids[1]);
  });

  test('restored session with an unknown step is detected as incompatible', () {
    final s = fresh().copyWith(currentStepId: 'removed_step');
    expect(engine.isCompatible(s), isFalse);
    expect(
      (run(s, ConfirmStep('removed_step')) as Rejected).reason,
      RejectReason.unknownStep,
    );
  });

  test('session JSON round trip', () {
    final s = (run(at(3), GoBack(ids[3])) as Accepted).session;
    final copy = WorkflowSession.fromJson(s.toJson());
    expect(copy.toJson(), s.toJson());
  });
}
