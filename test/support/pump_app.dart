import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/l10n/app_localizations.dart';
import 'package:focus_timer/ui/theme.dart';

/// Pumps [widget] inside the app's theme and English localization on a
/// phone-sized screen, so widget tests see the same environment as the app.
extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
  }) async {
    view.physicalSize = const Size(1080, 2340);
    view.devicePixelRatio = 3;
    addTearDown(view.reset);

    await pumpWidget(
      MaterialApp(
        theme: focusTheme(brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        home: widget,
      ),
    );
  }
}
