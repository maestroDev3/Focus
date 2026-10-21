import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/widgets/calm_motion.dart';
import 'package:focus_timer/ui/widgets/focus_background.dart';
import 'package:focus_timer/ui/widgets/neural_background.dart';

import '../../support/pump_app.dart';

void main() {
  const size = Size(360, 780);

  group('NeuralLayout', () {
    test('is the same for the same size and stays inside it', () {
      final first = NeuralLayout.generate(size);
      final second = NeuralLayout.generate(size);

      expect(first.nodes, second.nodes);
      expect(first.edges, second.edges);
      expect(first.nodes.length, greaterThanOrEqualTo(30));
      for (final node in first.nodes) {
        expect(node.dx, inInclusiveRange(0, size.width));
        expect(node.dy, inInclusiveRange(0, size.height));
      }
    });

    test('connects every node to at least one other', () {
      final layout = NeuralLayout.generate(size);

      for (var index = 0; index < layout.nodes.length; index++) {
        expect(
          layout.edges.any((edge) => edge.$1 == index || edge.$2 == index),
          isTrue,
          reason: 'node $index has no connection',
        );
      }
    });
  });

  group('NeuralBackground', () {
    NeuralPainter painter(WidgetTester tester) =>
        tester.widget<CustomPaint>(find.byKey(NeuralBackground.paintKey)).painter
            as NeuralPainter;

    Future<void> pumpNetwork(WidgetTester tester, {required bool motion}) async {
      await tester.pumpApp(
        CalmMotion(
          enabled: motion,
          child: const SizedBox.expand(child: NeuralBackground()),
        ),
      );
      await tester.pump();
    }

    testWidgets('lets pulses travel while motion is on', (tester) async {
      await pumpNetwork(tester, motion: true);
      final start = painter(tester).time;

      await tester.pump(const Duration(seconds: 2));

      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(painter(tester).time - start, greaterThan(1.5));
    });

    testWidgets('stays still while motion is off', (tester) async {
      await pumpNetwork(tester, motion: false);

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(painter(tester).time, 0);
    });

    testWidgets('lies behind the main screens with the glow', (tester) async {
      await tester.pumpApp(const FocusBackground(child: SizedBox.expand()));

      expect(find.byKey(FocusBackground.glowKey), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(FocusBackground),
          matching: find.byType(NeuralBackground),
        ),
        findsOneWidget,
      );
    });
  });
}
