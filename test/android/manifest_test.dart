import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final manifest = File(
    'android/app/src/main/AndroidManifest.xml',
  ).readAsStringSync();

  group('AndroidManifest', () {
    test('may see launcher apps through a <queries> entry', () {
      final queries = RegExp(
        r'<queries>([\s\S]*?)</queries>',
      ).firstMatch(manifest)?.group(1);

      expect(queries, contains('android.intent.action.MAIN'));
      expect(queries, contains('android.intent.category.LAUNCHER'));
    });

    test('does not request QUERY_ALL_PACKAGES', () {
      expect(manifest, isNot(contains('QUERY_ALL_PACKAGES')));
    });

    test('shows the app name Focus', () {
      expect(manifest, contains('android:label="Focus"'));
    });
  });
}
