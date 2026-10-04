import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';
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

      expect(find.text('Telegram is resting while you focus.'), findsOneWidget);
      expect(find.text('Telegram'), findsNothing);
      expect(find.text('18:00 remain in this session.'), findsOneWidget);
    });

    testWidgets('mentions a paused session without time', (tester) async {
      await tester.pumpApp(
        BlockedScreen(appLabel: 'Telegram', remaining: null, onReturn: () {}),
      );

      expect(find.text('Your session is paused.'), findsOneWidget);
    });

    testWidgets('names the end of a running focus time', (tester) async {
      await tester.pumpApp(
        BlockedScreen(
          appLabel: 'Telegram',
          remaining: null,
          focusTime: FocusTime(
            id: 'focus-time-1',
            weekdays: const {1, 2, 3, 4, 5},
            startMinute: 9 * 60,
            endMinute: 12 * 60,
          ),
          onReturn: () {},
        ),
      );

      expect(find.text('Focus time until 12:00'), findsOneWidget);
      expect(find.text('Your session is paused.'), findsNothing);
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
  
    testWidgets('names the block list of the focus time', (tester) async {
      await tester.pumpApp(
        BlockedScreen(
          appLabel: 'Instagram',
          remaining: null,
          focusTime: FocusTime(
            id: 'focus-time-1',
            weekdays: const {1, 2, 3, 4, 5},
            startMinute: 8 * 60,
            endMinute: 10 * 60,
            blockListId: 'list-1',
          ),
          blockListName: 'Morning',
          onReturn: () {},
        ),
      );

      expect(find.text('Morning · until 10:00'), findsOneWidget);
    });

    testWidgets('names the app in German', (tester) async {
      await tester.pumpApp(
        BlockedScreen(
          appLabel: 'Instagram',
          remaining: const Duration(minutes: 18),
          onReturn: () {},
        ),
        locale: const Locale('de'),
      );

      expect(
        find.text('Instagram ruht, während du im Fokus bist.'),
        findsOneWidget,
      );
    });
});
}
