import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/blocked_screen.dart';

import '../support/pump_app.dart';

void main() {
  group('BlockedScreen', () {
    testWidgets('shows the app and the remaining time', (tester) async {
      await tester.pumpApp(
        BlockedScreen(
          appLabel: 'Telegram',
          remaining: const Duration(minutes: 18),
          onReturn: () {},
        ),
      );

      expect(find.text('Telegram'), findsOneWidget);
      expect(find.text('Resting while you focus.'), findsOneWidget);
      expect(find.text('18:00 remain in this session.'), findsOneWidget);
    });

    testWidgets('mentions a paused session without time', (tester) async {
      await tester.pumpApp(
        BlockedScreen(appLabel: 'Telegram', remaining: null, onReturn: () {}),
      );

      expect(find.text('Your session is paused.'), findsOneWidget);
    });

    testWidgets('returns to focus', (tester) async {
      var returned = 0;
      await tester.pumpApp(
        BlockedScreen(
          appLabel: 'Telegram',
          remaining: const Duration(minutes: 18),
          onReturn: () => returned++,
        ),
      );

      await tester.tap(find.text('Return to focus'));
      await tester.pump();

      expect(returned, 1);
    });
  });
}
