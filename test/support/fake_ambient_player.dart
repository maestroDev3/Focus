import 'package:focus_timer/domain/ambient.dart';

/// Records what plays; null while silent.
class FakeAmbientPlayer implements AmbientPlayer {
  (AmbientSound, double)? playing;
  var plays = 0;

  @override
  Future<void> play(AmbientSound sound, {required double volume}) async {
    plays++;
    playing = (sound, volume);
  }

  @override
  Future<void> stop() async => playing = null;
}
