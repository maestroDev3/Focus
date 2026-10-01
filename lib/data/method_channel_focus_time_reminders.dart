import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/focus_time_reminders.dart';

/// Talks to `MainActivity` and `FocusTimeReminder` on Android.
class MethodChannelFocusTimeReminders implements FocusTimeReminders {
  MethodChannelFocusTimeReminders() {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'startRequested') _starts.add(null);
    });
  }

  static const channel = MethodChannel('de.maestrodev.focus_timer/reminders');

  final _starts = StreamController<void>.broadcast();

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

  @override
  Future<bool> initialStartRequest() async =>
      await channel.invokeMethod<bool>('initialStartRequest') ?? false;

  @override
  Stream<void> get startRequested => _starts.stream;
}
