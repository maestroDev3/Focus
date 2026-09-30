import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Release signing', () {
    test('uses a stable keystore from the repository', () {
      expect(File('android/app/focus-release.jks').existsSync(), isTrue);
    });

    test('defines a release signing config with the keystore password', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('create("release")'));
      expect(gradle, contains('focus-release.jks'));
      expect(gradle, contains('FOCUS_KEYSTORE_PASSWORD'));
    });

    test('builds with an increasing version code and checks the key', () {
      final ci = File('.github/workflows/ci.yml').readAsStringSync();

      expect(ci, contains(r'--build-number=${{ github.run_number }}'));
      expect(ci, contains('FOCUS_CERT_SHA256'));
    });
  });
}
