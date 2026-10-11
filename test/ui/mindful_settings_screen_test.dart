import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/ui/mindful_settings_screen.dart';

import '../support/fake_block_list_repository.dart';
import '../support/fake_installed_apps_source.dart';
import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

void main() {
  group('MindfulSettingsScreen', () {
    late FakeSettingsRepository settings;
    late FakeBlockListRepository mindfulApps;
    late int changes;

    Future<void> pumpScreen(WidgetTester tester) async {
      changes = 0;
      settings = FakeSettingsRepository()
        ..mindfulPause = const Duration(seconds: 10);
      mindfulApps = FakeBlockListRepository(
        const BlockList({'com.instagram.android', 'com.google.android.youtube'}),
      );
      await tester.pumpApp(
        MindfulSettingsScreen(
          settings: settings,
          mindfulApps: mindfulApps,
          installedApps: FakeInstalledAppsSource(),
          onChanged: () => changes++,
        ),
      );
      await tester.pump();
    }

    testWidgets('shows the stored pause and the number of apps', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Pause length'), findsOneWidget);
      final choice = tester.widget<SegmentedButton<Duration>>(
        find.byType(SegmentedButton<Duration>),
      );
      expect(choice.selected, {const Duration(seconds: 10)});
      for (final label in ['3 s', '5 s', '10 s', '20 s']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('2 apps'), findsOneWidget);
    });

    testWidgets('saves a new pause', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('3 s'));
      await tester.pump();

      expect(settings.mindfulPause, const Duration(seconds: 3));
      expect(changes, 1);
    });

    testWidgets('edits the mindful apps in the app picker', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Apps with a pause'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Apps with a pause'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);

      await tester.tap(find.text('Telegram'));
      await tester.pump();
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mindfulApps.blockList.contains('org.telegram.messenger'), isTrue);
      expect(find.text('3 apps'), findsOneWidget);
      expect(changes, 1);
    });
  });
}
