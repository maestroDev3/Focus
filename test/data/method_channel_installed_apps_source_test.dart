import 'package:flutter/services.dart';
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
  });
}
