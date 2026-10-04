import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/breath_screen.dart';

import '../support/pump_app.dart';

void main() {
  group('BreathScreen', () {
    late int opened;
    late int wentBack;

    Future<void> pumpBreath(WidgetTester tester, {int openedToday = 3}) async {
      opened = 0;
      wentBack = 0;
      await tester.pumpApp(
        BreathScreen(
          appLabel: 'Telegram',
          openedToday: openedToday,
          onOpen: () => opened++,
          onGoBack: () => wentBack++,
        ),
      );
    }

    testWidgets('names the app and how often it was opened today', (
      tester,
    ) async {
      await pumpBreath(tester);

      expect(find.text('Take a breath.'), findsOneWidget);
      expect(find.text('Do you really want to open Telegram?'), findsOneWidget);
      expect(find.text('Opened 3 times today'), findsOneWidget);
    });

    testWidgets('says once for the first opening', (tester) async {
      await pumpBreath(tester, openedToday: 1);

      expect(find.text('Opened once today'), findsOneWidget);
    });

    testWidgets('lets the app open only after 5 seconds', (tester) async {
      await pumpBreath(tester);
      expect(find.text('Open in 5 s'), findsOneWidget);

      await tester.tap(find.text('Open in 5 s'));
      await tester.pump(const Duration(seconds: 2));
      expect(opened, 0);
      expect(find.text('Open in 3 s'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Open Telegram'));
      await tester.pump();

      expect(opened, 1);
    });

    testWidgets('goes back at once', (tester) async {
      await pumpBreath(tester);

      await tester.tap(find.text('Go back'));
      await tester.pump();

      expect(wentBack, 1);
      expect(opened, 0);
    });
  });
}
