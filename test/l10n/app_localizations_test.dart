import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/l10n/app_localizations.dart';

void main() {
  group('AppLocalizations', () {
    test('supports English', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    });

    test('has the app title "Focus" in English', () {
      expect(lookupAppLocalizations(const Locale('en')).appTitle, 'Focus');
    });
  });

  group('app_en.arb', () {
    test('describes every message key', () {
      final arb =
          jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
              as Map<String, dynamic>;
      final messageKeys = arb.keys.where((key) => !key.startsWith('@'));

      expect(messageKeys, isNotEmpty);
      for (final key in messageKeys) {
        final metadata = arb['@$key'];
        expect(metadata, isA<Map<String, dynamic>>(), reason: '@$key missing');
        expect(
          (metadata as Map<String, dynamic>)['description'],
          isA<String>().having((text) => text.trim(), 'trimmed', isNotEmpty),
          reason: '@$key needs a description',
        );
      }
    });
  });
}
