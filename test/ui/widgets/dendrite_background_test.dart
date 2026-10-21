import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/background_style.dart';
import 'package:focus_timer/ui/widgets/calm_motion.dart';
import 'package:focus_timer/ui/widgets/dendrite_background.dart';
import 'package:focus_timer/ui/widgets/focus_background.dart';

import '../../support/pump_app.dart';

void main() {
  const size = Size(360, 780);
  const styles = [
    BackgroundStyle.fiveStems,
    BackgroundStyle.dense,
    BackgroundStyle.roots,
    BackgroundStyle.twoTrees,
    BackgroundStyle.mesh,
  ];

  group('DendriteLayout', () {
    test('is the same for the same style and size', () {
      for (final style in styles) {
        final first = DendriteLayout.generate(size, style);
        final second = DendriteLayout.generate(size, style);

        expect(
          [for (final branch in first.branches) branch.points],
          [for (final branch in second.branches) branch.points],
          reason: '$style',
        );
      }
    });

    test('grows in from outside the screen and reaches into it', () {
      final screen = Offset.zero & size;
      for (final style in styles) {
        final layout = DendriteLayout.generate(size, style);

        for (final root in layout.roots) {
          expect(
            screen.contains(layout.branches[root].points.first),
            isFalse,
            reason: '$style root $root starts inside',
          );
        }
        expect(
          layout.branches.any((branch) => branch.points.any(screen.contains)),
          isTrue,
          reason: '$style never reaches the screen',
        );
      }
    });

    test('has nothing for the style none', () {
      expect(
        DendriteLayout.generate(size, BackgroundStyle.none).branches,
        isEmpty,
      );
    });

    test('gets thinner and fainter with depth', () {
      for (final style in styles) {
        final spec = DendriteSpec.of(style);

        expect(spec.width(0), greaterThan(spec.width(3)), reason: '$style');
        expect(spec.opacity(0), greaterThan(spec.opacity(3)), reason: '$style');
      }
    });

    test('lets a pulse travel from a root to a tip without gaps', () {
      final layout = DendriteLayout.generate(size, BackgroundStyle.dense);

      for (var round = 0; round < 5; round++) {
        final (:root, :path) = layout.pulsePath(round: round, pulse: 1);
        expect(path.first, layout.branches[root].points.first);
        var branch = layout.branches[root];
        var index = 0;
        while (true) {
          for (final point in branch.points.skip(index == 0 ? 0 : 1)) {
            expect(path[index], point);
            index++;
          }
          if (branch.children.isEmpty) break;
          branch = layout.branches.firstWhere(
            (child) =>
                branch.children.contains(layout.branches.indexOf(child)) &&
                child.points.first == branch.points.last &&
                index < path.length &&
                child.points[1] == path[index],
          );
        }
        expect(index, path.length);
      }
    });
  });

  group('DendriteBackground', () {
    DendritePainter painter(WidgetTester tester) =>
        tester
                .widget<CustomPaint>(find.byKey(DendriteBackground.paintKey))
                .painter
            as DendritePainter;

    Future<void> pumpBackground(
      WidgetTester tester, {
      required bool motion,
    }) async {
      await tester.pumpApp(
        CalmMotion(
          enabled: motion,
          child: const SizedBox.expand(
            child: DendriteBackground(style: BackgroundStyle.roots),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('lets pulses travel while motion is on', (tester) async {
      await pumpBackground(tester, motion: true);
      final start = painter(tester).time;

      await tester.pump(const Duration(seconds: 2));

      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(painter(tester).time - start, greaterThan(1.5));
    });

    testWidgets('stays still while motion is off', (tester) async {
      await pumpBackground(tester, motion: false);

      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(painter(tester).time, 0);
    });
  });

  group('FocusBackground', () {
    testWidgets('shows the roots by default, with the glow', (tester) async {
      await tester.pumpApp(const FocusBackground(child: SizedBox.expand()));

      expect(find.byKey(FocusBackground.glowKey), findsOneWidget);
      final background = tester.widget<DendriteBackground>(
        find.byType(DendriteBackground),
      );
      expect(background.style, BackgroundStyle.roots);
    });

    testWidgets('shows the chosen style', (tester) async {
      await tester.pumpApp(
        const BackgroundChoice(
          style: BackgroundStyle.mesh,
          child: FocusBackground(child: SizedBox.expand()),
        ),
      );

      final background = tester.widget<DendriteBackground>(
        find.byType(DendriteBackground),
      );
      expect(background.style, BackgroundStyle.mesh);
    });

    testWidgets('leaves only the glow for none', (tester) async {
      await tester.pumpApp(
        const BackgroundChoice(
          style: BackgroundStyle.none,
          child: FocusBackground(child: SizedBox.expand()),
        ),
      );

      expect(find.byKey(FocusBackground.glowKey), findsOneWidget);
      expect(find.byType(DendriteBackground), findsNothing);
    });
  });
}
