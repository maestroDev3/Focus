import 'package:flutter/services.dart';

import '../domain/ambient.dart';

/// Talks to `AmbientPlayer` on Android, which loops the bundled sound.
class MethodChannelAmbientPlayer implements AmbientPlayer {
  const MethodChannelAmbientPlayer();

  static const channel = MethodChannel('de.maestrodev.focus_timer/ambient');

  @override
  Future<void> play(AmbientSound sound, {required double volume}) =>
      channel.invokeMethod<void>('play', {
        'sound': sound.name,
        'volume': volume,
      });

  @override
  Future<void> stop() => channel.invokeMethod<void>('stop');
}
