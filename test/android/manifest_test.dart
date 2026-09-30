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

    test('declares the app blocker accessibility service', () {
      final service = RegExp(
        r'<service[^>]*FocusBlockerService[\s\S]*?</service>',
      ).firstMatch(manifest)?.group(0);

      expect(
        service,
        contains('android.permission.BIND_ACCESSIBILITY_SERVICE'),
      );
      expect(
        service,
        contains('android.accessibilityservice.AccessibilityService'),
      );
      expect(service, contains('@xml/focus_blocker_service'));
    });

    test('lets the blocker see only window changes, not screen content', () {
      final config = File(
        'android/app/src/main/res/xml/focus_blocker_service.xml',
      ).readAsStringSync();

      expect(config, contains('typeWindowStateChanged'));
      expect(config, contains('android:canRetrieveWindowContent="false"'));
      expect(config, contains('@string/blocker_service_description'));
    });
  });
}
