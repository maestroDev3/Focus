import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

const _res = 'android/app/src/main/res';

/// Width and height from a PNG header (IHDR chunk).
(int, int) pngSize(String path) {
  final bytes = File(path).readAsBytesSync();
  final header = ByteData.sublistView(bytes, 16, 24);
  return (header.getUint32(0), header.getUint32(4));
}

void main() {
  group('App icon', () {
    test('is an adaptive icon with background, foreground and monochrome', () {
      final icon = File(
        '$_res/mipmap-anydpi-v26/ic_launcher.xml',
      ).readAsStringSync();

      expect(icon, contains('<adaptive-icon'));
      expect(icon, contains('<background'));
      expect(icon, contains('<foreground'));
      expect(icon, contains('<monochrome'));
    });

    test('draws the ring in champagne', () {
      final foreground = File(
        '$_res/drawable/ic_launcher_foreground.xml',
      ).readAsStringSync();

      expect(foreground.toUpperCase(), contains('#C9A96E'));
    });

    test('has legacy PNG icons in all densities', () {
      const sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192,
      };

      sizes.forEach((density, size) {
        expect(
          pngSize('$_res/mipmap-$density/ic_launcher.png'),
          (size, size),
          reason: density,
        );
      });
    });
  });
}
