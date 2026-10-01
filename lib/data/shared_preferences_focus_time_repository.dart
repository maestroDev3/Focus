import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/focus_time.dart';
import '../domain/focus_time_repository.dart';

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
    required Set<int> weekdays,
    required int startMinute,
    required int endMinute,
  }) async {
    final (:times, :nextId) = _load();
    final time = FocusTime(
      id: 'focus-time-$nextId',
      weekdays: weekdays,
      startMinute: startMinute,
      endMinute: endMinute,
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
          times: [
            for (final item in list)
              switch (item) {
                {
                  'id': final String id,
                  'weekdays': final List<Object?> weekdays,
                  'start': final int start,
                  'end': final int end,
                } =>
                  FocusTime(
                    id: id,
                    weekdays: weekdays.cast<int>().toSet(),
                    startMinute: start,
                    endMinute: end,
                  ),
                _ => throw FormatException('Malformed focus time: $item'),
              },
          ],
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
          for (final time in times)
            {
              'id': time.id,
              'weekdays': time.weekdays.toList()..sort(),
              'start': time.startMinute,
              'end': time.endMinute,
            },
        ],
      }),
    );
    _changes.add(times);
  }
}
