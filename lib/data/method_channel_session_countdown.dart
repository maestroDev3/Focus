import 'package:flutter/services.dart';

import '../domain/countdown.dart';
import '../domain/session_countdown.dart';

/// Localized texts of the countdown notification; `{label}` and `{time}` are
/// replaced here, so the platform only shows finished strings.
typedef CountdownTexts = ({
  String channelName,
  String focusing,
  String focusingWithLabel,
  String paused,
});

/// Talks to `SessionCountdown` on Android: an ongoing notification that
/// counts down by itself, also while Focus is closed.
class MethodChannelSessionCountdown implements SessionCountdown {
  const MethodChannelSessionCountdown({required this.texts});

  static const channel = MethodChannel('de.maestrodev.focus_timer/countdown');

  final CountdownTexts texts;

  @override
  Future<void> show(CountdownNotice notice) {
    final title = switch (notice.labelName) {
      final label? => texts.focusingWithLabel.replaceAll('{label}', label),
      null => texts.focusing,
    };
    final (paused, endMillis, text) = switch (notice) {
      CountdownRunning(:final end) => (
        false,
        end.millisecondsSinceEpoch,
        null,
      ),
      CountdownPaused(:final remaining) => (
        true,
        null,
        texts.paused.replaceAll('{time}', formatCountdown(remaining)),
      ),
    };
    return channel.invokeMethod<void>('show', {
      'channelName': texts.channelName,
      'title': title,
      'paused': paused,
      'endMillis': endMillis,
      'text': text,
    });
  }

  @override
  Future<void> hide() => channel.invokeMethod<void>('hide');
}
