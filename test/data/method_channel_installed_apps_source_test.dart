import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_installed_apps_source.dart';
import 'package:focus_timer/domain/blocking.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelInstalledAppsSource.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelInstalledAppsSource', () {
    test('maps the channel result to installed apps', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'installedApps');
        return [
          {'packageName': 'org.telegram.messenger', 'label': 'Telegram'},
          {'packageName': 'com.google.android.youtube', 'label': 'YouTube'},
        ];
      });

      expect(await const MethodChannelInstalledAppsSource().installedApps(), [
        const InstalledApp(
          packageName: 'org.telegram.messenger',
          label: 'Telegram',
        ),
        const InstalledApp(
          packageName: 'com.google.android.youtube',
          label: 'YouTube',
        ),
      ]);
    });

    test('rejects malformed entries', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        return [
          {'packageName': 42},
        ];
      });

      expect(
        const MethodChannelInstalledAppsSource().installedApps(),
        throwsFormatException,
      );
    });

    test('returns the icon of an app as PNG bytes', () async {
      final png = Uint8List.fromList([137, 80, 78, 71]);
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'appIcon');
        expect(call.arguments, 'org.telegram.messenger');
        return png;
      });

      expect(
        await const MethodChannelInstalledAppsSource().iconOf(
          'org.telegram.messenger',
        ),
        png,
      );
    });

    test('returns null when an app has no icon', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => null);

      expect(
        await const MethodChannelInstalledAppsSource().iconOf('unknown.app'),
        isNull,
      );
    });
  });
}
