import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/ui/permission_onboarding_screen.dart';

import '../support/pump_app.dart';

void main() {
  group('PermissionOnboardingScreen', () {
    testWidgets('explains what to do when the switch is greyed out', (
      tester,
    ) async {
      await tester.pumpApp(
        PermissionOnboardingScreen(
          title: 'Title',
          body: 'Body',
          onOpenSettings: () {},
          onOpenAppInfo: () {},
        ),
      );

      expect(find.textContaining('Allow restricted settings'), findsOneWidget);
    });

    testWidgets('opens the app info from its button', (tester) async {
      var opened = 0;
      await tester.pumpApp(
        PermissionOnboardingScreen(
          title: 'Title',
          body: 'Body',
          onOpenSettings: () {},
          onOpenAppInfo: () => opened++,
        ),
      );

      await tester.tap(find.text('Open app info'));
      await tester.pump();

      expect(opened, 1);
    });
  });
}
