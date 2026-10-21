import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/widgets/duration_wheel.dart';

import '../../support/pump_app.dart';

void main() {
  Duration? result;
  var closed = false;

  Future<void> openWheel(
    WidgetTester tester, {
    required Duration initial,
    Duration min = const Duration(minutes: 5),
    Duration max = const Duration(hours: 3),
  }) async {
    result = null;
    closed = false;
    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDurationWheel(
                context,
                title: 'Session length',
                initial: initial,
                min: min,
                max: max,
              );
              closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String item) async {
    await tester.tap(find.text(item));
    await tester.pumpAndSettle();
  }

  Future<void> done(WidgetTester tester) async {
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  }

  group('showDurationWheel', () {
    testWidgets('returns the hours and minutes picked on the wheels', (
      tester,
    ) async {
      await openWheel(tester, initial: const Duration(minutes: 25));

      expect(find.text('Session length'), findsOneWidget);
      await pick(tester, '1h');
      await pick(tester, '15 min');
      await done(tester);

      expect(result, const Duration(minutes: 75));
    });

    testWidgets('clamps a value below the minimum', (tester) async {
      await openWheel(
        tester,
        initial: const Duration(minutes: 10),
        min: const Duration(minutes: 10),
      );

      await pick(tester, '0 min');
      await done(tester);

      expect(result, const Duration(minutes: 10));
    });

    testWidgets('clamps a value above the maximum', (tester) async {
      await openWheel(tester, initial: const Duration(hours: 3));

      await pick(tester, '10 min');
      await done(tester);

      expect(result, const Duration(hours: 3));
    });

    testWidgets('rounds the initial value to the nearest step', (
      tester,
    ) async {
      await openWheel(tester, initial: const Duration(minutes: 23));

      await done(tester);

      expect(result, const Duration(minutes: 25));
    });

    testWidgets('returns null when dismissed', (tester) async {
      await openWheel(tester, initial: const Duration(minutes: 25));

      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(result, isNull);
    });
  });
}
