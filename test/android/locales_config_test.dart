import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Per-app language', () {
    test('the manifest points Android to the locales config', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();

      expect(manifest, contains('android:localeConfig="@xml/locales_config"'));
    });

    test('the locales config lists exactly the translated languages', () {
      final config = File(
        'android/app/src/main/res/xml/locales_config.xml',
      ).readAsStringSync();
      final listed = {
        for (final match in RegExp(
          r'<locale android:name="([\w-]+)"',
        ).allMatches(config))
          match.group(1)!,
      };
      final translated = {
        for (final file in Directory('lib/l10n').listSync())
          ?RegExp(r'app_(\w+)\.arb$').firstMatch(file.path)?.group(1),
      };

      expect(listed, translated);
    });
  });
}
