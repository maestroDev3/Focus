import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/home_screen.dart';

import '../support/pump_app.dart';

void main() {
  group('HomeScreen', () {
    Future<void> pumpHome(
      WidgetTester tester, {
      required DateTime now,
      VoidCallback? onStart,
    }) {
      return tester.pumpApp(
        HomeScreen(
          clock: () => now,
          focusDuration: const Duration(minutes: 25),
          onStart: onStart ?? () {},
        ),
      );
    }

    testWidgets('shows the date and an evening greeting at 20:00', (
      tester,
    ) async {
      await pumpHome(tester, now: DateTime(2026, 9, 29, 20));

      expect(find.text('Tuesday, September 29'), findsOneWidget);
      expect(find.text('Good evening.'), findsOneWidget);
    });

    testWidgets('greets in the morning and afternoon', (tester) async {
      await pumpHome(tester, now: DateTime(2026, 9, 29, 8));
      expect(find.text('Good morning.'), findsOneWidget);

      await pumpHome(tester, now: DateTime(2026, 9, 29, 14));
      expect(find.text('Good afternoon.'), findsOneWidget);
    });

    testWidgets('shows the planned duration', (tester) async {
      await pumpHome(tester, now: DateTime(2026, 9, 29, 20));

      expect(find.text('25 min'), findsOneWidget);
    });

    testWidgets('calls onStart once when Begin focus is tapped', (
      tester,
    ) async {
      var starts = 0;
      await pumpHome(
        tester,
        now: DateTime(2026, 9, 29, 20),
        onStart: () => starts++,
      );

      await tester.tap(find.text('Begin focus'));
      await tester.pump();

      expect(starts, 1);
    });

    testWidgets('makes Begin focus a tall FilledButton', (tester) async {
      await pumpHome(tester, now: DateTime(2026, 9, 29, 20));

      final button = find.widgetWithText(FilledButton, 'Begin focus');
      expect(button, findsOneWidget);
      expect(tester.getSize(button).height, greaterThanOrEqualTo(56));
    });
  });
}
