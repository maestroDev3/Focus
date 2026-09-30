import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Release signing', () {
    test('lets GitHub create the key from the user\'s secret password', () {
      final workflow = File(
        '.github/workflows/create-release-key.yml',
      ).readAsStringSync();

      expect(workflow, contains('workflow_dispatch'));
      expect(workflow, contains('keytool -genkeypair'));
      expect(workflow, contains('secrets.FOCUS_KEYSTORE_PASSWORD'));
      expect(workflow, contains('focus-release.sha256'));
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
      expect(ci, contains('focus-release.sha256'));
    });
  });
}
