import 'package:flutter/services.dart';

import '../domain/home_widget.dart';

/// Localized texts of the home screen widget; `{today}`, `{goal}` and
/// `{label}` are replaced here, so the widget only shows finished strings.
typedef HomeWidgetTexts = ({
  String start,
  String progress,
  String focusing,
  String focusingWithLabel,
  String countdownChannel,
});

/// Talks to `FocusWidgetProvider` on Android. The widget starts sessions on
/// its own from the published snapshot; Focus picks them up later.
class MethodChannelHomeWidgetBridge implements HomeWidgetBridge {
  const MethodChannelHomeWidgetBridge({
    required this.texts,
    required this.formatDuration,
  });

  static const channel = MethodChannel(
    'de.maestrodev.focus_timer/home_widget',
  );

  /// Read with every publish, so a new app language applies.
  final HomeWidgetTexts Function() texts;

  /// Formats today's focus time and the goal like the app does.
  final String Function(Duration duration) formatDuration;

  @override
  Future<void> publish(WidgetSnapshot snapshot) {
    final texts = this.texts();
    return channel.invokeMethod<void>('publish', {
      'focusMinutes': snapshot.focus.inMinutes,
      'labelId': snapshot.labelId,
      'progress': texts.progress
          .replaceAll('{today}', formatDuration(snapshot.focusedToday))
          .replaceAll('{goal}', formatDuration(snapshot.dailyGoal)),
      'start': texts.start,
      'countdownTitle': switch (snapshot.labelName) {
        final label? => texts.focusingWithLabel.replaceAll('{label}', label),
        null => texts.focusing,
      },
      'countdownChannel': texts.countdownChannel,
    });
  }

  @override
  Future<ExternalStart?> takePendingStart() async {
    final answer = await channel.invokeMapMethod<String, Object?>(
      'takePendingStart',
    );
    if (answer == null) return null;
    final (startMillis, plannedMinutes) = (
      answer['startMillis'],
      answer['plannedMinutes'],
    );
    if (startMillis is! int || plannedMinutes is! int) return null;
    return ExternalStart(
      start: DateTime.fromMillisecondsSinceEpoch(startMillis),
      planned: Duration(minutes: plannedMinutes),
      labelId: answer['labelId'] as String?,
    );
  }
}
