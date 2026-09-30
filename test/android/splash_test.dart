import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

String read(String path) => File('$_res/$path').readAsStringSync();

void main() {
  group('Splash screen', () {
    test('defines the noir color', () {
      expect(read('values/colors.xml').toUpperCase(), contains('#0E0D0B'));
    });

    for (final folder in ['values-v31', 'values-night-v31']) {
      test('uses noir and the ring on Android 12+ ($folder)', () {
        final styles = read('$folder/styles.xml');

        expect(
          styles,
          contains(
            '<item name="android:windowSplashScreenBackground">'
            '@color/focus_noir</item>',
          ),
        );
        expect(styles, contains('android:windowSplashScreenAnimatedIcon'));
      });
    }

    for (final folder in ['drawable', 'drawable-v21']) {
      test('shows the ring on noir before Android 12 ($folder)', () {
        final background = read('$folder/launch_background.xml');

        expect(background, contains('@color/focus_noir'));
        expect(background, contains('@drawable/splash_logo'));
      });
    }

    test('never uses a light window behind the app', () {
      for (final folder in ['values', 'values-night']) {
        expect(read('$folder/styles.xml'), isNot(contains('Theme.Light')));
      }
    });
  });
}
