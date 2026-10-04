import 'focus_time.dart';

/// Stores the user's recurring focus times. They never overlap.
abstract interface class FocusTimeRepository {
  /// Emits all focus times now and after every change.
  Stream<List<FocusTime>> watchFocusTimes();

  /// Adds a focus time; throws [ArgumentError] if it is invalid or overlaps.
  Future<FocusTime> addFocusTime({
    required Set<int> weekdays,
    required int startMinute,
    required int endMinute,
    String? blockListId,
  });

  /// Replaces the focus time with the same id; throws [ArgumentError] if it
  /// would overlap another one.
  Future<void> updateFocusTime(FocusTime time);

  Future<void> deleteFocusTime(String id);

  /// Replaces all focus times with [times], keeping their ids (restoring a
  /// backup).
  Future<void> replaceAll(List<FocusTime> times);
}

