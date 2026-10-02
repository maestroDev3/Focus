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

    test('declares the notification listener that holds notifications', () {
      final service = RegExp(
        r'<service[^>]*FocusNotificationGate[\s\S]*?</service>',
      ).firstMatch(manifest)?.group(0);

      expect(
        service,
        contains('android.permission.BIND_NOTIFICATION_LISTENER_SERVICE'),
      );
      expect(
        service,
        contains('android.service.notification.NotificationListenerService'),
      );
    });

    test('may post notifications and reschedule reminders after a restart', () {
      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android.permission.RECEIVE_BOOT_COMPLETED'));
    });

    test('asks for exact alarms only as a timer app (decision 2026-10-02)', () {
      expect(manifest, contains('android.permission.USE_EXACT_ALARM'));
      final scheduleExact = RegExp(
        r'<uses-permission[^>]*SCHEDULE_EXACT_ALARM[^>]*/>',
      ).firstMatch(manifest)?.group(0);
      expect(scheduleExact, contains('android:maxSdkVersion="32"'));
    });

    test('declares the private session-end receiver', () {
      final receiver = RegExp(
        r'<receiver[^>]*SessionEndReceiver[\s\S]*?</receiver>',
      ).firstMatch(manifest)?.group(0);

      expect(receiver, contains('android:exported="false"'));
      expect(receiver, contains('android.intent.action.BOOT_COMPLETED'));
    });

    test('declares the private focus time reminder receiver', () {
      final receiver = RegExp(
        r'<receiver[^>]*FocusTimeReminderReceiver[\s\S]*?</receiver>',
      ).firstMatch(manifest)?.group(0);

      expect(receiver, contains('android:exported="false"'));
      expect(receiver, contains('android.intent.action.BOOT_COMPLETED'));
      expect(receiver, contains('android.intent.action.MY_PACKAGE_REPLACED'));
    });
  });
}
