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
  }) async {
    await tester.pumpApp(
      CalmMotion(
        enabled: motion,
        child: Center(
          child: SizedBox.square(
            dimension: 200,
            child: BreathingRing(progress: progress),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('BreathingRing', () {
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
