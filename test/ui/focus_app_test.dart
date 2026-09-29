import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/l10n/app_localizations.dart';
import 'package:focus_timer/ui/focus_app.dart';
import 'package:focus_timer/ui/theme.dart';

import '../support/pump_app.dart';

void main() {
  group('FocusApp', () {
    testWidgets('shows the localized app title on the home screen', (
      tester,
    ) async {
      await tester.pumpWidget(const FocusApp());

      expect(find.text('Focus'), findsOneWidget);
    });

    testWidgets('uses the light and dark focus themes following the system', (
      tester,
    ) async {
      await tester.pumpWidget(const FocusApp());

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme?.colorScheme, focusTheme(Brightness.light).colorScheme);
      expect(
        app.darkTheme?.colorScheme,
        focusTheme(Brightness.dark).colorScheme,
      );
      expect(app.themeMode, ThemeMode.system);
    });

    testWidgets('no longer contains the counter demo', (tester) async {
      await tester.pumpWidget(const FocusApp());

      expect(find.byIcon(Icons.add), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
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
