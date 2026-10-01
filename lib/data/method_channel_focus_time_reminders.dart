import 'package:flutter/services.dart';

import '../domain/focus_time_reminders.dart';

/// Talks to `MainActivity` and `FocusTimeReminder` on Android.
class MethodChannelFocusTimeReminders implements FocusTimeReminders {
  static const channel = MethodChannel('de.maestrodev.focus_timer/reminders');

  @override
  Future<void> reschedule(ReminderTexts texts) =>
      channel.invokeMethod<void>('reschedule', {
        'channelName': texts.channelName,
        'title': texts.title,
        'body': texts.body,
      });

  @override
  Future<void> requestPermission() =>
      channel.invokeMethod<void>('requestPermission');
}
