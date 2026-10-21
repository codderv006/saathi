import 'dart:async';

import '../../../core/services/debug_log.dart';
import '../domain/workflow.dart';
import '../domain/workflow_store.dart';

/// Phone-first persistence with a cloud copy.
///
/// - The local store is authoritative: a step only advances once it is saved on the
///   phone, so the guide works with bad or no network.
/// - Each accepted change is then copied to the cloud in the background. A failed
///   copy is logged and never blocks or rolls back progress.
/// - On restore, whichever copy has the newer revision of the session wins.
class SyncedWorkflowStore implements WorkflowStore {
  SyncedWorkflowStore({
    required this.local,
    required this.remote,
    this.remoteTimeout = const Duration(seconds: 3),
  });

  final WorkflowStore local;
  final WorkflowStore remote;
  final Duration remoteTimeout;

  /// Last cloud sync result, for diagnostics.
  Object? lastSyncError;
  Future<void> _pendingSync = Future.value();

  @override
  String get name => 'phone + ${remote.name}';

  @override
  Future<void> save(
    WorkflowSession session, {
    required int expectedRevision,
  }) async {
    await local.save(session, expectedRevision: expectedRevision);
    _pendingSync = _sync(session);
  }

  Future<void> _sync(WorkflowSession session) async {
    try {
      await remote.save(session, expectedRevision: session.revision - 1);
      lastSyncError = null;
    } catch (e) {
      lastSyncError = e;
      log('sync', 'cloud copy failed for rev ${session.revision}: $e');
    }
  }

  /// Test hook: completes when the latest background copy has finished.
  Future<void> get idle => _pendingSync;

  @override
  Future<WorkflowSession?> loadActive() async {
    final onPhone = await local.loadActive();
    WorkflowSession? inCloud;
    try {
      inCloud = await remote.loadActive().timeout(remoteTimeout);
    } catch (e) {
      log('sync', 'cloud restore skipped: $e');
    }
    if (inCloud == null) return onPhone;
    final cloudIsNewer =
        onPhone == null ||
        (inCloud.id == onPhone.id
            ? inCloud.revision > onPhone.revision
            : inCloud.updatedAt.isAfter(onPhone.updatedAt));
    if (!cloudIsNewer) return onPhone;
    // Adopt the cloud copy locally so later saves continue from it.
    await local.clear();
    await local.save(inCloud, expectedRevision: 0);
    log('sync', 'restored newer cloud copy rev ${inCloud.revision}');
    return inCloud;
  }

  @override
  Future<void> clear() async {
    await local.clear();
    unawaited(
      remote.clear().catchError((Object e) {
        log('sync', 'cloud clear failed: $e');
      }),
    );
  }
}
