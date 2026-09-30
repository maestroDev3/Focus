import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/focus_session.dart';
import '../domain/session_repository.dart';
import 'session_codec.dart';

/// Stores sessions as versioned JSON in shared preferences.
class SharedPreferencesSessionRepository implements SessionRepository {
  SharedPreferencesSessionRepository(this._preferences);

  static const activeKey = 'sessions.active.v1';
  static const finishedKey = 'sessions.finished.v1';

  final SharedPreferences _preferences;
  final _finishedChanges = StreamController<List<FocusSession>>.broadcast();

  @override
  Future<FocusSession?> loadActive() async {
    final stored = _preferences.getString(activeKey);
    if (stored == null) return null;
    return decodeSession(_object(jsonDecode(stored)));
  }

  @override
  Future<void> saveActive(FocusSession? session) async {
    if (session == null) {
      await _preferences.remove(activeKey);
    } else {
      await _preferences.setString(
        activeKey,
        jsonEncode(encodeSession(session)),
      );
    }
  }

  @override
  Future<void> addFinished(FocusSession session) async {
    final sessions = [..._loadFinished(), session];
    await _preferences.setString(
      finishedKey,
      jsonEncode([for (final item in sessions) encodeSession(item)]),
    );
    _finishedChanges.add(sessions);
  }

  @override
  Future<void> replaceFinished(List<FocusSession> sessions) async {
    await _preferences.setString(
      finishedKey,
      jsonEncode([for (final item in sessions) encodeSession(item)]),
    );
    _finishedChanges.add(List.of(sessions));
  }

  @override
  Stream<List<FocusSession>> watchFinished() async* {
    yield _loadFinished();
    yield* _finishedChanges.stream;
  }

  List<FocusSession> _loadFinished() {
    final stored = _preferences.getString(finishedKey);
    if (stored == null) return [];
    final list = jsonDecode(stored);
    if (list is! List<Object?>) {
      throw const FormatException('Finished sessions must be a list.');
    }
    return [for (final item in list) decodeSession(_object(item))];
  }

  Map<String, Object?> _object(Object? json) {
    if (json is Map<String, Object?>) return json;
    throw FormatException('Expected a JSON object, got $json');
  }
}
