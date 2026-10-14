import 'focus_session.dart';
import 'settings_repository.dart';

/// Calm sounds bundled with Focus (#122); [off] plays nothing and
/// [musicApp] continues whatever the user's music app played last (#266).
enum AmbientSound {
  off,
  rain,
  softNoise,
  deepNoise,
  fireplace,
  oceanWaves,
  musicApp;

  /// Whether Focus plays the sound itself from a bundled file.
  bool get isBundled => this != off && this != musicApp;
}

/// The sound chosen on the home screen and its volume (0–1).
class AmbientChoice {
  const AmbientChoice({required this.sound, required this.volume})
    : assert(volume >= 0 && volume <= 1);

  /// Off at 60 % until the user chooses a sound.
  static const initial = AmbientChoice(sound: AmbientSound.off, volume: 0.6);

  final AmbientSound sound;
  final double volume;

  @override
  bool operator ==(Object other) =>
      other is AmbientChoice && other.sound == sound && other.volume == volume;

  @override
  int get hashCode => Object.hash(sound, volume);
}

/// Plays one looping sound at a time.
abstract interface class AmbientPlayer {
  Future<void> play(AmbientSound sound, {required double volume});

  Future<void> stop();
}

/// Plays the chosen sound while a session runs and stops it when the session
/// is paused or over.
class AmbientSync {
  AmbientSync({required this.player, required this.settings});

  final AmbientPlayer player;
  final SettingsRepository settings;

  Future<void> update(FocusSession? session) async {
    final choice = await settings.loadAmbient();
    final running = session != null && !session.isFinished && !session.isPaused;
    if (!running || choice.sound == AmbientSound.off) {
      await player.stop();
      return;
    }
    await player.play(choice.sound, volume: choice.volume);
  }
}
