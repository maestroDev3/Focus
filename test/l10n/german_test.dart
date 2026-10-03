import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/l10n/app_localizations.dart';

import '../support/pump_app.dart';

Map<String, Object?> _arb(String name) =>
    jsonDecode(File('lib/l10n/$name').readAsStringSync())
        as Map<String, Object?>;

/// Placeholder names used in an ICU message, e.g. `{count}` or `{label}`.
Set<String> _placeholders(String message) => {
  for (final match in RegExp(r'\{(\w+)[,}]').allMatches(message))
    match.group(1)!,
};

void main() {
  group('German translation', () {
    test('translates every message with the same placeholders', () {
      final english = _arb('app_en.arb');
      final german = _arb('app_de.arb');

      for (final MapEntry(:key, :value) in english.entries) {
        if (key.startsWith('@')) continue;
        expect(german, contains(key), reason: 'missing German text for $key');
        expect(
          _placeholders(german[key]! as String),
          _placeholders(value! as String),
          reason: 'placeholders differ for $key',
        );
      }
    });

    testWidgets('shows German texts with a German locale', (tester) async {
      await tester.pumpApp(
        Builder(
          builder: (context) => Text(AppLocalizations.of(context).beginFocus),
        ),
        locale: const Locale('de'),
      );

      expect(find.text('Fokus beginnen'), findsOneWidget);
    });
  });
}
