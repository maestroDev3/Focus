import 'package:flutter/services.dart';

import '../domain/session_end_alarm.dart';

/// Localized texts of the native session-end notification.
typedef SessionEndTexts = ({String channelName, String title, String body});

/// Talks to `SessionEndAlarm` on Android, which posts the notification with
/// an exact alarm, also while Focus is closed or after a restart.
class MethodChannelSessionEndAlarm implements SessionEndAlarm {
  const MethodChannelSessionEndAlarm({required this.texts});

  static const channel = MethodChannel('de.maestrodev.focus_timer/session_end');

  /// Sent with every schedule call, so the notification needs no Flutter.
  final SessionEndTexts texts;

  @override
  Future<void> scheduleAt(DateTime end) =>
      channel.invokeMethod<void>('schedule', {
        'endMillis': end.millisecondsSinceEpoch,
        'channelName': texts.channelName,
        'title': texts.title,
        'body': texts.body,
      });

  @override
  Future<void> cancel() => channel.invokeMethod<void>('cancel');
}
