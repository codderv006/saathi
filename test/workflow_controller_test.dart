import 'package:flutter_test/flutter_test.dart';
import 'package:saathi_poc/features/guided_workflow/data/local_workflow_store.dart';
import 'package:saathi_poc/features/guided_workflow/data/ride_workflow.dart';
import 'package:saathi_poc/features/guided_workflow/data/workflow_registry.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow_controller.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow_engine.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemoryStore implements WorkflowStore {
  WorkflowSession? stored;
  bool failNextSave = false;
  bool failLoad = false;
  int saves = 0;

  @override
  String get name => 'memory';

  @override
  Future<void> save(
    WorkflowSession session, {
    required int expectedRevision,
  }) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('simulated network failure');
    }
    final current = stored?.id == session.id ? stored!.revision : 0;
    if (current != expectedRevision) {
      throw StaleRevisionException(expectedRevision, current);
    }
    stored = session;
    saves++;
  }

  @override
  Future<WorkflowSession?> loadActive() async {
    if (failLoad) throw StateError('offline');
    return stored;
  }

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  final olaWorkflow = WorkflowRegistry.find(
    RideApp.ola.workflowId(fromInstall: false),
  )!;
  final engine = WorkflowEngine(olaWorkflow);
  final ids = olaWorkflow.steps.map((s) => s.id).toList();
  final t0 = DateTime.utc(2026, 10, 21);
  late MemoryStore store;
  late WorkflowController controller;

  setUp(() async {
    store = MemoryStore();
    controller = WorkflowController(
      store: store,
      findDefinition: WorkflowRegistry.find,
      clock: () => t0,
    );
    await controller.startNew(
      definition: olaWorkflow,
      sessionId: 's1',
      installationId: 'i1',
      language: 'mr',
    );
  });

  test('failed save does not advance; retry works', () async {
    store.failNextSave = true;
    expect(await controller.apply(ConfirmStep(ids[0])), isA<SaveFailed>());
    expect(controller.session!.currentStepId, ids[0]);
    expect(store.stored!.currentStepId, ids[0]);
    expect(await controller.apply(ConfirmStep(ids[0])), isA<Applied>());
    expect(controller.session!.currentStepId, ids[1]);
  });

  test('concurrent duplicate confirmations advance only once', () async {
    final results = await Future.wait([
      controller.apply(ConfirmStep(ids[0])),
      controller.apply(ConfirmStep(ids[0])),
    ]);
    expect(results.whereType<Applied>(), hasLength(1));
    expect(results.whereType<Refused>(), hasLength(1));
    expect(controller.session!.currentStepId, ids[1]);
    expect(store.stored!.revision, 2);
  });

  test('repeat/help/simpler are not persisted', () async {
    final before = store.saves;
    await controller.apply(const RepeatInstruction());
    await controller.apply(const RequestHelp());
    await controller.apply(const ExplainSimpler());
    expect(store.saves, before);
  });

  test('stale writer cannot overwrite newer stored progress', () async {
    await controller.apply(ConfirmStep(ids[0])); // rev 2
    // Another writer advanced the stored copy to rev 3.
    store.stored =
        (engine.apply(store.stored!, ConfirmStep(ids[1]), t0) as Accepted)
            .session;
    final outcome = await controller.apply(GoBack(ids[1]));
    expect((outcome as SaveFailed).error, isA<StaleRevisionException>());
    expect(store.stored!.currentStepId, ids[2]);
  });

  group('voice requests', () {
    test('"done" from voice only asks for on-screen confirmation', () async {
      final r = await controller.applyVoiceRequest({
        'action': 'request_step_confirmation',
        'step_id': ids[0],
      });
      expect(r, isA<NeedsUserConfirmation>());
      expect(controller.session!.currentStepId, ids[0]);
      expect(controller.pendingVoiceConfirmation, ids[0]);
      await controller.apply(ConfirmStep(ids[0]));
      expect(controller.pendingVoiceConfirmation, isNull);
    });

    test('voice confirmation for a non-current step is refused', () async {
      final r = await controller.applyVoiceRequest({
        'action': 'request_step_confirmation',
        'step_id': ids[4],
      });
      expect(r, isA<Refused>());
      expect(controller.pendingVoiceConfirmation, isNull);
    });

    test('model cannot write state or declare completion', () async {
      for (final payload in [
        {'action': 'set_step', 'step_id': ids[6]},
        {'action': 'request_step_confirmation', 'current_step_id': ids[6]},
        {'action': 'request_workflow_completion'},
        {'action': 'request_step_confirmation'},
      ]) {
        expect(
          await controller.applyVoiceRequest(payload),
          anyOf(isA<InvalidRequest>(), isA<Refused>()),
          reason: '$payload',
        );
      }
      expect(controller.session!.currentStepId, ids[0]);
      expect(store.saves, 1);
    });

    test('voice repeat/help keep the step', () async {
      await controller.applyVoiceRequest({
        'action': 'request_repeat_instruction',
      });
      await controller.applyVoiceRequest({'action': 'request_help'});
      expect(controller.session!.currentStepId, ids[0]);
    });
  });

  group('restore', () {
    test('restores the saved step after a "restart"', () async {
      await controller.apply(ConfirmStep(ids[0]));
      final restarted = WorkflowController(
        store: store,
        findDefinition: WorkflowRegistry.find,
      );
      expect(await restarted.restore(), RestoreResult.restored);
      expect(restarted.session!.currentStepId, ids[1]);
      expect(restarted.session!.language, 'mr');
    });

    test('completed session restores as closed, not active', () async {
      for (var i = 0; i < ids.length - 1; i++) {
        await controller.apply(ConfirmStep(ids[i]));
      }
      await controller.apply(ReportOutcome(ids.last, Outcome.succeeded));
      final restarted = WorkflowController(
        store: store,
        findDefinition: WorkflowRegistry.find,
      );
      await restarted.restore();
      expect(restarted.session!.status, SessionStatus.completed);
      expect(restarted.session!.isOpen, isFalse);
    });

    test('saved session for an unknown guide is incompatible', () async {
      store.stored = store.stored!.copyWith();
      final json = store.stored!.toJson()..['workflowId'] = 'whatsapp_v1';
      store.stored = WorkflowSession.fromJson(json);
      final restarted = WorkflowController(
        store: store,
        findDefinition: WorkflowRegistry.find,
      );
      expect(await restarted.restore(), RestoreResult.incompatible);
    });

    test('incompatible saved step is reported, not crashed on', () async {
      store.stored = store.stored!.copyWith(currentStepId: 'gone');
      final restarted = WorkflowController(
        store: store,
        findDefinition: WorkflowRegistry.find,
      );
      expect(await restarted.restore(), RestoreResult.incompatible);
      expect(restarted.session, isNull);
    });

    test('storage failure on restore is reported', () async {
      store.failLoad = true;
      final restarted = WorkflowController(
        store: store,
        findDefinition: WorkflowRegistry.find,
      );
      expect(await restarted.restore(), RestoreResult.failed);
    });
  });

  test(
    'LocalWorkflowStore persists, checks revisions, ignores corrupt data',
    () async {
      SharedPreferences.setMockInitialValues({});
      final local = LocalWorkflowStore();
      final s = engine.start(
        sessionId: 'x',
        installationId: 'i',
        language: 'en',
        now: t0,
      );
      await local.save(s, expectedRevision: 0);
      expect((await local.loadActive())!.id, 'x');
      expect(
        () => local.save(s, expectedRevision: 0),
        throwsA(isA<StaleRevisionException>()),
      );
      SharedPreferences.setMockInitialValues({
        'saathi.activeSession': '{not json',
      });
      expect(await LocalWorkflowStore().loadActive(), isNull);
    },
  );
}
