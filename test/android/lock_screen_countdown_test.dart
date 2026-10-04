import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_settings_repository.dart';

void main() {
  group('Lock screen countdown', () {
    test('may post the countdown as a Live Update (Android 16)', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(
        manifest,
        contains('android.permission.POST_PROMOTED_NOTIFICATIONS'),
      );
    });

    test('the native countdown reads the setting the app writes', () {
      final countdown = File(
        'android/app/src/main/kotlin/de/maestrodev/focus_timer/'
        'SessionCountdown.kt',
      ).readAsStringSync();

      // shared_preferences prefixes every key with “flutter.”.
      expect(
        countdown,
        contains(
          '"flutter.${SharedPreferencesSettingsRepository.lockScreenKey}"',
        ),
      );
    });
  });
}
