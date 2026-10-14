import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_ambient_player.dart';
import 'package:focus_timer/domain/ambient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelAmbientPlayer.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelAmbientPlayer', () {
    test('plays a sound with its volume', () async {
      await const MethodChannelAmbientPlayer().play(
        AmbientSound.softNoise,
        volume: 0.6,
      );

      expect(calls.single.method, 'play');
      expect(calls.single.arguments, {'sound': 'softNoise', 'volume': 0.6});
    });

    test('stops the sound', () async {
      await const MethodChannelAmbientPlayer().stop();

      expect(calls.single.method, 'stop');
    });
  });
}
