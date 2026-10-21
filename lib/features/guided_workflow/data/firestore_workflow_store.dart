import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/workflow.dart';
import '../domain/workflow_store.dart';

/// Cloud copy of guide sessions (see firebase/firestore.rules):
///   sessions/{sessionId}   session JSON + ownerUid
///   users/{uid}            { activeSessionId, installationId, language, updatedAt }
/// The uid comes from Firebase anonymous auth. Rules only accept increasing
/// revisions, so a stale or duplicate write is rejected server-side too.
class FirestoreWorkflowStore implements WorkflowStore {
  FirestoreWorkflowStore(this._db, this.uid);

  final FirebaseFirestore _db;
  final String uid;

  @override
  String get name => 'Firestore';

  DocumentReference<Map<String, dynamic>> _session(String id) =>
      _db.collection('sessions').doc(id);
  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(uid);

  /// Plain writes (no transaction) so they queue while offline; ordering and the
  /// revision rule keep the cloud copy consistent.
  @override
  Future<void> save(
    WorkflowSession session, {
    required int expectedRevision,
  }) async {
    final batch = _db.batch()
      ..set(_session(session.id), {
        ...session.toJson(),
        'ownerUid': uid,
        'serverUpdatedAt': FieldValue.serverTimestamp(),
      })
      ..set(_user, {
        'activeSessionId': session.id,
        'installationId': session.installationId,
        'language': session.language,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    await batch.commit();
  }

  @override
  Future<WorkflowSession?> loadActive() async {
    final user = await _user.get();
    final sessionId = user.data()?['activeSessionId'] as String?;
    if (sessionId == null) return null;
    final snap = await _session(sessionId).get();
    if (!snap.exists) return null;
    final json = Map<String, Object?>.from(snap.data()!)
      ..remove('ownerUid')
      ..remove('serverUpdatedAt');
    return WorkflowSession.fromJson(json);
  }

  @override
  Future<void> clear() async {
    final user = await _user.get();
    final sessionId = user.data()?['activeSessionId'] as String?;
    final batch = _db.batch()..delete(_user);
    if (sessionId != null) batch.delete(_session(sessionId));
    await batch.commit();
  }
}
