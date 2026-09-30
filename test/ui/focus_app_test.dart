import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_timer.dart';
import 'package:focus_timer/domain/pomodoro.dart';
import 'package:focus_timer/l10n/app_localizations.dart';
import 'package:focus_timer/ui/focus_app.dart';
import 'package:focus_timer/ui/theme.dart';

import '../support/fake_app_blocker.dart';
import '../support/fake_block_list_repository.dart';
import '../support/fake_installed_apps_source.dart';
import '../support/fake_session_repository.dart';
import '../support/fake_settings_repository.dart';
import '../support/pump_app.dart';

void main() {
  var now = DateTime(2026, 9, 29, 20);
  var repository = FakeSessionRepository();
  var settings = FakeSettingsRepository();
  var blockList = FakeBlockListRepository();
  var blocker = FakeAppBlocker();
  FocusApp buildApp() => FocusApp(
    timer: FocusTimer(repository: repository, clock: () => now),
    settings: settings,
    blockList: blockList,
    installedApps: FakeInstalledAppsSource(),
    appBlocker: blocker,
    clock: () => now,
  );

  setUp(() {
    now = DateTime(2026, 9, 29, 20);
    repository = FakeSessionRepository();
    settings = FakeSettingsRepository();
    blockList = FakeBlockListRepository();
    blocker = FakeAppBlocker();
  });

  Future<void> elapse(WidgetTester tester, Duration duration) async {
    now = now.add(duration);
    await tester.pump(duration);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> beginFocus(WidgetTester tester) async {
    await tester.tap(find.text('Begin focus'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('FocusApp', () {
    testWidgets('starts on the home screen', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.text('Begin focus'), findsOneWidget);
      expect(find.text('Good evening.'), findsOneWidget);
    });

    testWidgets('uses the light and dark focus themes following the system', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.colorScheme, focusTheme(Brightness.light).colorScheme);
      expect(
        app.darkTheme?.colorScheme,
        focusTheme(Brightness.dark).colorScheme,
      );
      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('no longer contains the counter demo', (tester) async {
      await tester.pumpWidget(buildApp());

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('FocusApp navigation', () {
    testWidgets('Begin focus opens the session screen', (tester) async {
      await tester.pumpWidget(buildApp());

      await tester.tap(find.text('Begin focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('ending the session returns home', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.tap(find.text('Begin focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.widgetWithText(OutlinedButton, 'End session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(TextButton, 'End session'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Begin focus'), findsOneWidget);
    });
  });

  group('FocusApp breaks', () {
    testWidgets('offers a short break after the first session of the day', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await beginFocus(tester);

      await elapse(tester, const Duration(minutes: 25));

      expect(find.text('Short break · 5 min'), findsOneWidget);
    });

    testWidgets('offers a long break after the fourth session of the day', (
      tester,
    ) async {
      for (var hour = 1; hour <= 3; hour++) {
        repository.finished.add(
          FocusSession(
            start: now.subtract(Duration(hours: hour)),
            planned: const Duration(minutes: 25),
          ).complete(),
        );
      }
      await tester.pumpWidget(buildApp());
      await beginFocus(tester);

      await elapse(tester, const Duration(minutes: 25));

      expect(find.text('Long break · 15 min'), findsOneWidget);
    });

    testWidgets('returns home after skipping the break', (tester) async {
      await tester.pumpWidget(buildApp());
      await beginFocus(tester);
      await elapse(tester, const Duration(minutes: 25));

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Begin focus'), findsOneWidget);
    });
  });

  group('FocusApp settings', () {
    testWidgets('uses the configured focus duration', (tester) async {
      settings.pomodoro = const PomodoroSettings(
        focus: Duration(minutes: 50),
      );
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('50 min'), findsOneWidget);

      await beginFocus(tester);
      expect(find.text('50:00'), findsOneWidget);
    });

    testWidgets('uses the configured break duration', (tester) async {
      settings.pomodoro = const PomodoroSettings(
        shortBreak: Duration(minutes: 10),
      );
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await beginFocus(tester);

      await elapse(tester, const Duration(minutes: 25));

      expect(find.text('Short break · 10 min'), findsOneWidget);
    });

    testWidgets('opens the settings and shows changes on home', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Long break after'), findsOneWidget);

      await tester.tap(find.byKey(const Key('focus-increase')));
      await tester.pump();
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('30 min'), findsOneWidget);
    });
  });

  group('FocusApp blocked apps', () {
    testWidgets('shows the number of paused apps and updates it', (
      tester,
    ) async {
      blockList.blockList = const BlockList().add('org.telegram.messenger');
      await tester.pumpWidget(buildApp());
      await tester.pump();
      expect(find.text('1 app paused'), findsOneWidget);

      await tester.tap(find.text('1 app paused'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('YouTube'));
      await tester.pump();
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('2 apps paused'), findsOneWidget);
    });
  });

  group('FocusApp app blocking', () {
    testWidgets('shows the blocked screen when a paused app is opened', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pump();
      await beginFocus(tester);

      blocker.emit('org.telegram.messenger');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('25:00 remain in this session.'), findsOneWidget);

      await tester.tap(find.text('Return to focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('restores the session when launched for a blocked app', (
      tester,
    ) async {
      repository.active = FocusSession(
        start: now.subtract(const Duration(minutes: 5)),
        planned: const Duration(minutes: 25),
      );
      blocker.initial = 'org.telegram.messenger';

      await tester.pumpWidget(buildApp());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('20:00 remain in this session.'), findsOneWidget);

      await tester.tap(find.text('Return to focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('20:00'), findsOneWidget);
    });

    testWidgets('guides to the settings when blocking is not allowed', (
      tester,
    ) async {
      blockList.blockList = const BlockList().add('org.telegram.messenger');
      blocker.enabled = false;
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.tap(find.text('Allow app blocking'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Open settings'));
      await tester.pump();

      expect(blocker.openedSettings, 1);
    });

    testWidgets('guides to notification access when it is missing', (
      tester,
    ) async {
      blockList.blockList = const BlockList().add('org.telegram.messenger');
      blocker.notificationGateEnabled = false;
      await tester.pumpWidget(buildApp());
      await tester.pump();

      await tester.tap(find.text('Allow holding notifications'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Hold notifications while you focus'), findsOneWidget);
      await tester.tap(find.text('Open settings'));
      await tester.pump();

      expect(blocker.openedNotificationSettings, 1);
    });

    testWidgets('shows no hint when blocking is allowed', (tester) async {
      blockList.blockList = const BlockList().add('org.telegram.messenger');
      await tester.pumpWidget(buildApp());
      await tester.pump();

      expect(find.text('Allow app blocking'), findsNothing);
      expect(find.text('Allow holding notifications'), findsNothing);
    });
  });

  group('pumpApp', () {
    testWidgets('provides localizations to the pumped widget', (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => Text(AppLocalizations.of(context).appTitle),
        ),
      );

      expect(find.text('Focus'), findsOneWidget);
    });
  });
}
