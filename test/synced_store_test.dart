import 'package:flutter_test/flutter_test.dart';
import 'package:saathi_poc/features/guided_workflow/data/ride_workflow.dart';
import 'package:saathi_poc/features/guided_workflow/data/synced_workflow_store.dart';
import 'package:saathi_poc/features/guided_workflow/data/workflow_registry.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow_controller.dart';
import 'package:saathi_poc/features/guided_workflow/domain/workflow_engine.dart';

import 'support/fakes.dart';

class FlakyRemote extends MemoryStore {
  bool offline = false;

  @override
  String get name => 'cloud';

  @override
  Future<void> save(
    WorkflowSession session, {
    required int expectedRevision,
  }) async {
    if (offline) throw StateError('offline');
    // Mirror the Firestore rule: revisions only increase.
    if (stored != null &&
        stored!.id == session.id &&
        session.revision <= stored!.revision) {
      throw StateError('PERMISSION_DENIED');
    }
    stored = session;
  }

  @override
  Future<WorkflowSession?> loadActive() async {
    if (offline) throw StateError('offline');
    return stored;
  }
}

void main() {
  final ola = WorkflowRegistry.find(
    RideApp.ola.workflowId(fromInstall: false),
  )!;
  final engine = WorkflowEngine(ola);
  final ids = ola.steps.map((s) => s.id).toList();
  late MemoryStore phone;
  late FlakyRemote cloud;
  late SyncedWorkflowStore store;
  late WorkflowController controller;

  setUp(() async {
    phone = MemoryStore();
    cloud = FlakyRemote();
    store = SyncedWorkflowStore(local: phone, remote: cloud);
    controller = WorkflowController(
      store: store,
      findDefinition: WorkflowRegistry.find,
    );
    await controller.startNew(
      definition: ola,
      sessionId: 's1',
      installationId: 'i1',
      language: 'en',
      userId: 'uid-1',
    );
    await store.idle;
  });

  test('accepted steps reach both the phone and the cloud', () async {
    await controller.apply(ConfirmStep(ids[0]));
    await store.idle;
    expect(phone.stored!.currentStepId, ids[1]);
    expect(cloud.stored!.currentStepId, ids[1]);
    expect(cloud.stored!.userId, 'uid-1');
  });

  test('offline cloud never blocks or rolls back progress', () async {
    cloud.offline = true;
    final outcome = await controller.apply(ConfirmStep(ids[0]));
    await store.idle;
    expect(outcome, isA<Applied>());
    expect(phone.stored!.currentStepId, ids[1]);
    expect(store.lastSyncError, isNotNull);
    // Back online: the next change syncs the latest state.
    cloud.offline = false;
    await controller.apply(ConfirmStep(ids[1]));
    await store.idle;
    expect(cloud.stored!.currentStepId, ids[2]);
    expect(store.lastSyncError, isNull);
  });

  test('phone save failure still refuses to advance', () async {
    phone.failNextSave = true;
    expect(await controller.apply(ConfirmStep(ids[0])), isA<SaveFailed>());
    expect(controller.session!.currentStepId, ids[0]);
  });

  test('restore prefers the newer cloud copy and adopts it locally', () async {
    await controller.apply(ConfirmStep(ids[0])); // rev 2 on both
    await store.idle;
    cloud.stored =
        (engine.apply(cloud.stored!, ConfirmStep(ids[1]), DateTime.now())
                as Accepted)
            .session; // rev 3 only in the cloud
    final restarted = WorkflowController(
      store: store,
      findDefinition: WorkflowRegistry.find,
    );
    expect(await restarted.restore(), RestoreResult.restored);
    expect(restarted.session!.revision, 3);
    expect(phone.stored!.revision, 3, reason: 'cloud copy adopted');
  });

  test('restore keeps the phone copy when the cloud is unreachable', () async {
    await controller.apply(ConfirmStep(ids[0]));
    await store.idle;
    cloud.offline = true;
    final restarted = WorkflowController(
      store: store,
      findDefinition: WorkflowRegistry.find,
    );
    expect(await restarted.restore(), RestoreResult.restored);
    expect(restarted.session!.currentStepId, ids[1]);
  });

  test('empty phone (e.g. cleared data) restores from the cloud', () async {
    await controller.apply(ConfirmStep(ids[0]));
    await store.idle;
    phone.stored = null;
    final restarted = WorkflowController(
      store: store,
      findDefinition: WorkflowRegistry.find,
    );
    expect(await restarted.restore(), RestoreResult.restored);
    expect(restarted.session!.currentStepId, ids[1]);
  });
}
