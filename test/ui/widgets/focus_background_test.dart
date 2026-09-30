import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/daily_goal.dart';
import 'package:focus_timer/domain/focus_timer.dart';
import 'package:focus_timer/domain/pomodoro.dart';
import 'package:focus_timer/ui/break_screen.dart';
import 'package:focus_timer/ui/home_screen.dart';
import 'package:focus_timer/ui/session_screen.dart';
import 'package:focus_timer/ui/theme.dart';
import 'package:focus_timer/ui/widgets/focus_background.dart';

import '../../support/fake_session_repository.dart';
import '../../support/pump_app.dart';

void main() {
  final now = DateTime(2026, 9, 30, 20);

  Color glowColor(WidgetTester tester) {
    final glow = tester.widget<DecoratedBox>(
      find.byKey(FocusBackground.glowKey),
    );
    final gradient = (glow.decoration as BoxDecoration).gradient;
    return (gradient as RadialGradient).colors.first;
  }

  void expectTransparentScaffold(WidgetTester tester) {
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, Colors.transparent);
  }

  group('FocusBackground', () {
    for (final brightness in Brightness.values) {
      testWidgets('glows softly in the primary color ($brightness)', (
        tester,
      ) async {
        await tester.pumpApp(
          const FocusBackground(child: SizedBox.expand()),
          brightness: brightness,
        );

        final primary = focusTheme(brightness).colorScheme.primary;
        final glow = glowColor(tester);
        expect(glow.r, primary.r);
        expect(glow.g, primary.g);
        expect(glow.b, primary.b);
        expect(glow.a, inInclusiveRange(0.05, 0.3));
      });
    }
  });

  group('Main screens', () {
    testWidgets('home is drawn on the background', (tester) async {
      await tester.pumpApp(
        HomeScreen(
          clock: () => now,
          focusDuration: const Duration(minutes: 25),
          onStart: () {},
          onOpenSettings: () {},
          labelName: null,
          hasLabels: false,
          onChooseLabel: () {},
          focusedToday: Duration.zero,
          dailyGoal: const DailyGoal(),
          onOpenStatistics: () {},
        ),
      );

      expect(find.byType(FocusBackground), findsOneWidget);
      expectTransparentScaffold(tester);
    });

    testWidgets('the session is drawn on the background', (tester) async {
      final timer = FocusTimer(
        repository: FakeSessionRepository(),
        clock: () => now,
      );
      await timer.start(const Duration(minutes: 25));
      await tester.pumpApp(
        SessionScreen(timer: timer, clock: () => now, onDone: (_) {}),
      );

      expect(find.byType(FocusBackground), findsOneWidget);
      expectTransparentScaffold(tester);
    });

    testWidgets('the break is drawn on the background', (tester) async {
      await tester.pumpApp(
        BreakScreen(
          kind: BreakKind.short,
          duration: const Duration(minutes: 5),
          clock: () => now,
          onDone: () {},
        ),
      );

      expect(find.byType(FocusBackground), findsOneWidget);
      expectTransparentScaffold(tester);
    });
  });
}
