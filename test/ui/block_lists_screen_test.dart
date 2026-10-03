import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/named_block_list.dart';
import 'package:focus_timer/ui/block_lists_screen.dart';

import '../support/fake_block_list_repository.dart';
import '../support/fake_installed_apps_source.dart';
import '../support/fake_named_block_list_repository.dart';
import '../support/pump_app.dart';

void main() {
  const telegram = 'org.telegram.messenger';
  const youtube = 'com.google.android.youtube';
  late FakeBlockListRepository defaultList;
  late FakeNamedBlockListRepository namedLists;

  setUp(() {
    defaultList = FakeBlockListRepository(
      const BlockList().add(telegram).add(youtube),
    );
    namedLists = FakeNamedBlockListRepository([
      NamedBlockList(
        id: 'list-1',
        name: 'Morning',
        apps: const BlockList().add(youtube),
      ),
    ]);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpApp(
      BlockListsScreen(
        apps: FakeInstalledAppsSource(),
        defaultList: defaultList,
        namedLists: namedLists,
        activeSession: null,
      ),
    );
    await tester.pump();
  }

  group('BlockListsScreen', () {
    testWidgets('shows the default list and named lists with counts', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Default list'), findsOneWidget);
      expect(find.text('2 apps · sessions and focus times'), findsOneWidget);
      expect(find.text('Morning'), findsOneWidget);
      expect(find.text('1 app'), findsOneWidget);
    });

    testWidgets('adds a named list', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('New list'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Evening');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Evening'), findsOneWidget);
      expect(namedLists.lists.map((list) => list.name), contains('Evening'));
    });

    testWidgets('renames a named list', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Options for Morning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Deep work');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Deep work'), findsOneWidget);
      expect(namedLists.lists.single.name, 'Deep work');
    });

    testWidgets('deletes a named list but offers no delete for the default', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byTooltip('Options for Default list'), findsNothing);
      await tester.tap(find.byTooltip('Options for Morning'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Morning'), findsNothing);
      expect(namedLists.lists, isEmpty);
    });

    testWidgets('edits only the opened named list', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Morning'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AppBar, 'Morning'), findsOneWidget);
      await tester.tap(find.text('Telegram'));
      await tester.pump();

      expect(namedLists.lists.single.apps.contains(telegram), isTrue);
      expect(defaultList.blockList, const BlockList().add(telegram).add(youtube));
    });

    testWidgets('opens the default list in the app picker', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Default list'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Telegram'));
      await tester.pump();

      expect(defaultList.blockList.contains(telegram), isFalse);
    });
  });
}
