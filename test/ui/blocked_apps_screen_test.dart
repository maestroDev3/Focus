import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/ui/blocked_apps_screen.dart';

import '../support/fake_block_list_repository.dart';
import '../support/fake_installed_apps_source.dart';
import '../support/pump_app.dart';

void main() {
  const telegram = 'org.telegram.messenger';
  const youtube = 'com.google.android.youtube';
  final start = DateTime(2026, 9, 30, 10);

  Future<FakeBlockListRepository> pumpScreen(
    WidgetTester tester, {
    BlockList initial = const BlockList(),
    FocusSession? activeSession,
  }) async {
    final repository = FakeBlockListRepository(initial);
    await tester.pumpApp(
      BlockedAppsScreen(
        apps: FakeInstalledAppsSource(),
        blockList: repository,
        activeSession: activeSession,
      ),
    );
    await tester.pump();
    return repository;
  }

  bool isChecked(WidgetTester tester, String label) => tester
      .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label))
      .value ?? false;

  bool isEnabled(WidgetTester tester, String label) =>
      tester
          .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label))
          .onChanged !=
      null;

  group('BlockedAppsScreen', () {
    testWidgets('lists the installed apps with their block state', (
      tester,
    ) async {
      await pumpScreen(tester, initial: const BlockList().add(telegram));

      expect(find.text('Instagram'), findsOneWidget);
      expect(isChecked(tester, 'Telegram'), isTrue);
      expect(isChecked(tester, 'YouTube'), isFalse);
    });

    testWidgets('checking saves and unchecking removes without a session', (
      tester,
    ) async {
      final repository = await pumpScreen(tester);

      await tester.tap(find.text('YouTube'));
      await tester.pump();
      expect(repository.blockList.contains(youtube), isTrue);

      await tester.tap(find.text('YouTube'));
      await tester.pump();
      expect(repository.blockList.contains(youtube), isFalse);
    });

    testWidgets('keeps blocked apps locked while a session runs', (
      tester,
    ) async {
      final repository = await pumpScreen(
        tester,
        initial: const BlockList().add(telegram),
        activeSession: FocusSession(
          start: start,
          planned: const Duration(minutes: 25),
        ),
      );

      expect(isEnabled(tester, 'Telegram'), isFalse);
      expect(
        find.text('While you focus, apps can be added but not removed.'),
        findsOneWidget,
      );

      await tester.tap(find.text('YouTube'));
      await tester.pump();
      expect(repository.blockList.contains(youtube), isTrue);
      expect(isEnabled(tester, 'YouTube'), isFalse);
    });

    testWidgets('filters the list by name', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byType(TextField), 'tele');
      await tester.pump();

      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('YouTube'), findsNothing);
      expect(find.text('Instagram'), findsNothing);
    });
  });
}
