import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/widgets/breathing_ring.dart';
import 'package:focus_timer/ui/widgets/calm_motion.dart';

import '../../support/pump_app.dart';

void main() {
  GoalRingPainter painter(WidgetTester tester) =>
      tester.widget<CustomPaint>(find.byKey(BreathingRing.paintKey)).painter
          as GoalRingPainter;

  Future<void> pumpRing(
    WidgetTester tester, {
    required bool motion,
    double progress = 0.5,
    double protectedProgress = 0,
  }) async {
    await tester.pumpApp(
      CalmMotion(
        enabled: motion,
        child: Center(
          child: SizedBox.square(
            dimension: 200,
            child: BreathingRing(
              progress: progress,
              protectedProgress: protectedProgress,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  const ringSize = Size(200, 200);
  const center = Offset(100, 100);
  final inner = Rect.fromCircle(
    center: center,
    radius: GoalRingPainter.innerRadius(ringSize),
  );
  final outer = Rect.fromCircle(
    center: center,
    radius: GoalRingPainter.outerRadius(ringSize),
  );

  group('BreathingRing', () {
    test('keeps the protected ring outside the session ring', () {
      expect(
        GoalRingPainter.outerRadius(ringSize) -
            GoalRingPainter.innerRadius(ringSize),
        greaterThanOrEqualTo(6),
      );
    });

    testWidgets('paints protected time on its own outer ring', (tester) async {
      await pumpRing(tester, motion: false, protectedProgress: 0.4);

      expect(
        find.byKey(BreathingRing.paintKey),
        paints
          ..arc(rect: outer)
          ..arc(rect: inner),
      );
    });

    testWidgets('closes the outer ring when the goal is protected', (
      tester,
    ) async {
      await pumpRing(tester, motion: false, protectedProgress: 1.9);

      expect(painter(tester).protectedProgress, 1.9);
      expect(find.byKey(BreathingRing.paintKey), paints..arc(rect: outer));
    });

    testWidgets('paints no outer ring without protected time', (tester) async {
      await pumpRing(tester, motion: false);

      expect(
        find.byKey(BreathingRing.paintKey),
        isNot(paints..arc(rect: outer)),
      );
    });

    testWidgets('shows the progress on the arc', (tester) async {
      await pumpRing(tester, motion: false, progress: 0.62);

      expect(painter(tester).progress, closeTo(0.62, 0.001));
    });

    testWidgets('breathes while motion is on', (tester) async {
      await pumpRing(tester, motion: true);
      final first = painter(tester).breath;

      await tester.pump(const Duration(milliseconds: 1400));
      final later = painter(tester).breath;

      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(later, isNot(closeTo(first, 0.05)));
    });

    testWidgets('stays still while motion is off', (tester) async {
      await pumpRing(tester, motion: false);

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(painter(tester).breath, 0);
    });
  });

  group('CalmMotion', () {
    testWidgets('is off when Android removes animations', (tester) async {
      late bool motion;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CalmMotion(
            enabled: true,
            child: Builder(
              builder: (context) {
                motion = CalmMotion.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(motion, isFalse);
    });

    testWidgets('is off without a CalmMotion above', (tester) async {
      late bool motion;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            motion = CalmMotion.of(context);
            return const SizedBox();
          },
        ),
      );

      expect(motion, isFalse);
    });
  });
}
