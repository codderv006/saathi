import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/workflow.dart';
import '../domain/workflow_store.dart';

/// On-device persistence (SharedPreferences). Works offline and without Firebase.
class LocalWorkflowStore implements WorkflowStore {
  static const _key = 'saathi.activeSession';

  @override
  String get name => 'on this phone';

  @override
  Future<void> save(
    WorkflowSession session, {
    required int expectedRevision,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = _decode(prefs.getString(_key));
    final storedRevision = stored?.id == session.id ? stored!.revision : 0;
    if (storedRevision != expectedRevision) {
      throw StaleRevisionException(expectedRevision, storedRevision);
    }
    if (!await prefs.setString(_key, jsonEncode(session.toJson()))) {
      throw StateError('Could not write to device storage');
    }
  }

  @override
  Future<WorkflowSession?> loadActive() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(_key));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  WorkflowSession? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return WorkflowSession.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return null; // corrupt or old-format data: treat as nothing saved
    }
  }
}
