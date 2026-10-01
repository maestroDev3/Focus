/// Localized texts for the native reminder; `{time}` in [title] is replaced
/// with the end of the focus time.
typedef ReminderTexts = ({String channelName, String title, String body});

/// Calm notifications when a focus time starts, scheduled natively so they
/// also arrive while Focus is closed or after a restart.
abstract interface class FocusTimeReminders {
  /// Schedules the reminder for the next focus time start, read from the
  /// published blocking state.
  Future<void> reschedule(ReminderTexts texts);

  /// Asks for permission to post notifications, if not granted yet.
  Future<void> requestPermission();

  /// Whether Focus was launched by tapping the reminder (consumed once).
  Future<bool> initialStartRequest();

  /// Taps on the reminder while Focus is running.
  Stream<void> get startRequested;
}
