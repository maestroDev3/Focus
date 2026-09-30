import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_app_blocker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelAppBlocker.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'isBlockerEnabled' => true,
        'initialBlockedPackage' => 'org.telegram.messenger',
        _ => null,
      };
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelAppBlocker', () {
    test('reports whether the blocker service is enabled', () async {
      expect(await MethodChannelAppBlocker().isBlockerEnabled(), isTrue);
    });

    test('opens the accessibility settings', () async {
      await MethodChannelAppBlocker().openBlockerSettings();

      expect(calls.single.method, 'openBlockerSettings');
    });

    test('reports the blocked app Focus was launched for', () async {
      expect(
        await MethodChannelAppBlocker().initialBlockedPackage(),
        'org.telegram.messenger',
      );
    });

    test('emits blocked apps opened while Focus runs', () async {
      final blocker = MethodChannelAppBlocker();
      final opened = <String>[];
      final subscription = blocker.blockedAppOpened.listen(opened.add);
      addTearDown(subscription.cancel);

      await messenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(
          const MethodCall('blockedAppOpened', 'com.instagram.android'),
        ),
        (_) {},
      );

      expect(opened, ['com.instagram.android']);
    });
  });
}
