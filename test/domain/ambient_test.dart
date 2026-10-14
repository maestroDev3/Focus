import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/ambient.dart';
import 'package:focus_timer/domain/focus_timer.dart';

import '../support/fake_ambient_player.dart';
import '../support/fake_session_repository.dart';
import '../support/fake_settings_repository.dart';

void main() {
  final tenOClock = DateTime(2026, 10, 14, 10);
  const planned = Duration(minutes: 25);
  late FakeAmbientPlayer player;
  late FakeSettingsRepository settings;
  late DateTime now;
  late FocusTimer timer;

  setUp(() {
    player = FakeAmbientPlayer();
    settings = FakeSettingsRepository()
      ..ambient = const AmbientChoice(sound: AmbientSound.rain, volume: 0.4);
    now = tenOClock;
    timer = FocusTimer(
      repository: FakeSessionRepository(),
      clock: () => now,
      ambient: AmbientSync(player: player, settings: settings),
    );
  });

  test('offers off and five calm sounds, off at 60 % by default', () {
    expect(AmbientSound.values, [
      AmbientSound.off,
      AmbientSound.rain,
      AmbientSound.softNoise,
      AmbientSound.deepNoise,
      AmbientSound.fireplace,
      AmbientSound.oceanWaves,
    ]);
    expect(
      AmbientChoice.initial,
      const AmbientChoice(sound: AmbientSound.off, volume: 0.6),
    );
  });

  group('AmbientSync', () {
    test('plays the chosen sound while a session runs', () async {
      await timer.start(planned);

      expect(player.playing, (AmbientSound.rain, 0.4));
    });

    test('stops on pause and plays again on resume', () async {
      await timer.start(planned);

      await timer.pause();
      expect(player.playing, isNull);

      await timer.resume();
      expect(player.playing, (AmbientSound.rain, 0.4));
    });

    test('stops when the session is ended or completed', () async {
      await timer.start(planned);
      await timer.cancel();
      expect(player.playing, isNull);

      await timer.start(planned);
      now = now.add(planned);
      await timer.completeIfDue();
      expect(player.playing, isNull);
    });

    test('never plays with the sound off', () async {
      settings.ambient = const AmbientChoice(
        sound: AmbientSound.off,
        volume: 0.6,
      );

      await timer.start(planned);

      expect(player.playing, isNull);
      expect(player.plays, 0);
    });

    test('a new choice applies to the running session', () async {
      await timer.start(planned);
      settings.ambient = const AmbientChoice(
        sound: AmbientSound.fireplace,
        volume: 0.8,
      );

      await timer.refreshAmbient();

      expect(player.playing, (AmbientSound.fireplace, 0.8));
    });
  });
}
