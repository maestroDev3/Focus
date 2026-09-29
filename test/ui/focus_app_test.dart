import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_timer.dart';
import 'package:focus_timer/l10n/app_localizations.dart';
import 'package:focus_timer/ui/focus_app.dart';
import 'package:focus_timer/ui/theme.dart';

import '../support/fake_session_repository.dart';
import '../support/pump_app.dart';

void main() {
  DateTime now = DateTime(2026, 9, 29, 20);
  FocusApp app() => FocusApp(
    timer: FocusTimer(repository: FakeSessionRepository(), clock: () => now),
    clock: () => now,
  );

  setUp(() => now = DateTime(2026, 9, 29, 20));

  group('FocusApp', () {
    testWidgets('starts on the home screen', (tester) async {
      await tester.pumpWidget(app());

      expect(find.text('Begin focus'), findsOneWidget);
      expect(find.text('Good evening.'), findsOneWidget);
    });

    testWidgets('uses the light and dark focus themes following the system', (
      tester,
    ) async {
      await tester.pumpWidget(app());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.colorScheme, focusTheme(Brightness.light).colorScheme);
      expect(
        app.darkTheme?.colorScheme,
        focusTheme(Brightness.dark).colorScheme,
      );
      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('no longer contains the counter demo', (tester) async {
      await tester.pumpWidget(app());

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });

  group('FocusApp navigation', () {
    testWidgets('Begin focus opens the session screen', (tester) async {
      await tester.pumpWidget(app());

      await tester.tap(find.text('Begin focus'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('25:00'), findsOneWidget);
    });

    testWidgets('ending the session returns home', (tester) async {
      await tester.pumpWidget(app());
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
