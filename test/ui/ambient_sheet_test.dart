import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/ambient.dart';
import 'package:focus_timer/ui/ambient_sheet.dart';

import '../support/pump_app.dart';

void main() {
  group('AmbientSheet', () {
    late List<AmbientChoice> changes;

    Future<void> pumpSheet(WidgetTester tester) async {
      changes = [];
      await tester.pumpApp(
        Scaffold(
          body: AmbientSheet(
            initial: const AmbientChoice(sound: AmbientSound.off, volume: 0.6),
            onChanged: changes.add,
          ),
        ),
      );
    }

    testWidgets('lists off, the five sounds and the music app', (tester) async {
      await pumpSheet(tester);

      for (final name in [
        'Off',
        'Rain',
        'Soft noise',
        'Deep noise',
        'Fireplace',
        'Ocean waves',
        'Your music app',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Volume'), findsOneWidget);
    });

    testWidgets('reports the chosen sound with the volume', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Fireplace'));
      await tester.pump();

      expect(
        changes.last,
        const AmbientChoice(sound: AmbientSound.fireplace, volume: 0.6),
      );
    });

    testWidgets('reports a new volume', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Rain'));
      await tester.pump();
      final slider = find.byType(Slider);
      await tester.tapAt(
        tester.getTopLeft(slider) + Offset(tester.getSize(slider).width - 30, 20),
      );
      await tester.pump();

      expect(changes.last.sound, AmbientSound.rain);
      expect(changes.last.volume, greaterThan(0.8));
    });

    testWidgets('hides the volume for the music app', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Your music app'));
      await tester.pump();

      expect(changes.last.sound, AmbientSound.musicApp);
      expect(find.text('Volume'), findsNothing);
      expect(find.byType(Slider), findsNothing);
    });
  });
}
