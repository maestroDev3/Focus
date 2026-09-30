import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/intro_screen.dart';

import '../support/pump_app.dart';

void main() {
  group('IntroScreen', () {
    testWidgets('shows the wordmark and tagline, then finishes', (
      tester,
    ) async {
      var done = 0;
      await tester.pumpApp(IntroScreen(onDone: () => done++));

      expect(find.text('FOCUS'), findsOneWidget);
      expect(find.text('One quiet hour at a time.'), findsOneWidget);
      expect(done, 0);

      await tester.pump(const Duration(milliseconds: 1200));

      expect(done, 1);
    });
  });
}
