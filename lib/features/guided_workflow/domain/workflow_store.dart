import 'workflow.dart';

/// Persistence port. Implementations: LocalWorkflowStore (device) now; a Firestore
/// store when Firebase is configured (Phase 6).
abstract class WorkflowStore {
  String get name;

  /// Persists [session] only if the stored revision for that session id is still
  /// [expectedRevision] (0 = must not exist yet). Throws on any failure.
  Future<void> save(WorkflowSession session, {required int expectedRevision});

  /// The session this installation was last working on, if any.
  Future<WorkflowSession?> loadActive();

  Future<void> clear();
}

class StaleRevisionException implements Exception {
  StaleRevisionException(this.expected, this.actual);
  final int expected;
  final int? actual;
  @override
  String toString() =>
      'StaleRevisionException(expected $expected, stored $actual)';
}
