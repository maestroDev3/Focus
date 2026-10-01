import 'dart:async';

import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/domain/focus_time_repository.dart';

/// In-memory [FocusTimeRepository] for tests, with the same overlap rule.
class FakeFocusTimeRepository implements FocusTimeRepository {
  FakeFocusTimeRepository([List<FocusTime> times = const []])
    : times = List.of(times);

  final List<FocusTime> times;
  final _changes = StreamController<List<FocusTime>>.broadcast();
  var _nextId = 100;

  @override
  Stream<List<FocusTime>> watchFocusTimes() async* {
    yield List.of(times);
    yield* _changes.stream;
  }

  @override
  Future<FocusTime> addFocusTime({
    required Set<int> weekdays,
    required int startMinute,
    required int endMinute,
  }) async {
    final time = FocusTime(
      id: 'focus-time-${_nextId++}',
      weekdays: weekdays,
      startMinute: startMinute,
      endMinute: endMinute,
    );
    checkNoOverlap(times, time);
    times.add(time);
    _changes.add(List.of(times));
    return time;
  }

  @override
  Future<void> updateFocusTime(FocusTime time) async {
    checkNoOverlap(times, time);
    final index = times.indexWhere((other) => other.id == time.id);
    times[index] = time;
    _changes.add(List.of(times));
  }

  @override
  Future<void> deleteFocusTime(String id) async {
    times.removeWhere((time) => time.id == id);
    _changes.add(List.of(times));
  }
}
