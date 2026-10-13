import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/focus_time.dart';
import '../domain/focus_time_repository.dart';
import '../domain/id_counter.dart';
import 'focus_time_codec.dart';

/// Stores focus times as versioned JSON (`focus_times.v1`).
class SharedPreferencesFocusTimeRepository implements FocusTimeRepository {
  SharedPreferencesFocusTimeRepository(this._preferences);

  static const key = 'focus_times.v1';
  static const _version = 1;

  final SharedPreferences _preferences;
  final _changes = StreamController<List<FocusTime>>.broadcast();

  @override
  Stream<List<FocusTime>> watchFocusTimes() async* {
    yield _load().times;
    yield* _changes.stream;
  }

  @override
  Future<FocusTime> addFocusTime({
    required List<FocusTimeRange> ranges,
    String? blockListId,
  }) async {
    final (:times, :nextId) = _load();
    final time = FocusTime.withRanges(
      id: 'focus-time-$nextId',
      ranges: ranges,
      blockListId: blockListId,
    );
    checkNoOverlap(times, time);
    await _save([...times, time], nextId + 1);
    return time;
  }

  @override
  Future<void> updateFocusTime(FocusTime time) async {
    final (:times, :nextId) = _load();
    checkNoOverlap(times, time);
    await _save([
      for (final other in times) other.id == time.id ? time : other,
    ], nextId);
  }

  @override
  Future<void> deleteFocusTime(String id) async {
    final (:times, :nextId) = _load();
    await _save([
      for (final time in times)
        if (time.id != id) time,
    ], nextId);
  }

  @override
  Future<void> replaceAll(List<FocusTime> times) async {
    final (times: _, :nextId) = _load();
    await _save(
      List.of(times),
      nextFreeIdNumber(nextId, [for (final time in times) time.id]),
    );
  }

  ({List<FocusTime> times, int nextId}) _load() {
    final stored = _preferences.getString(key);
    if (stored == null) return (times: const [], nextId: 1);
    return switch (jsonDecode(stored)) {
      {
        'v': _version,
        'nextId': final int nextId,
        'times': final List<Object?> list,
      } =>
        (
          times: [for (final item in list) decodeFocusTime(item)],
          nextId: nextId,
        ),
      _ => throw FormatException('Unknown focus times data: $stored'),
    };
  }

  Future<void> _save(List<FocusTime> times, int nextId) async {
    await _preferences.setString(
      key,
      jsonEncode({
        'v': _version,
        'nextId': nextId,
        'times': [
          for (final time in times) encodeFocusTime(time),
        ],
      }),
    );
    _changes.add(times);
  }
}
