/// Tells the user when a session ends, also while Focus is closed: the
/// platform posts a notification at the scheduled time.
abstract interface class SessionEndAlarm {
  /// Schedules the end notification at [end], replacing any earlier one.
  Future<void> scheduleAt(DateTime end);

  /// Removes the pending end notification, e.g. after a pause.
  Future<void> cancel();
}
