import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/ambient.dart';

/// `softNoise` → `soft_noise`, as Android resource names need it.
String _snake(String name) => name.replaceAllMapped(
  RegExp('[A-Z]'),
  (match) => '_${match[0]!.toLowerCase()}',
);

void main() {
  test('every sound is bundled as an Android resource', () {
    for (final sound in AmbientSound.values) {
      if (!sound.isBundled) continue;
      final file = File(
        'android/app/src/main/res/raw/ambient_${_snake(sound.name)}.ogg',
      );
      expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
    }
  });
}
