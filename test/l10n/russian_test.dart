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

/// String names defined in an Android `strings.xml`.
Set<String> _androidStrings(String folder) => {
  for (final match in RegExp(r'<string name="(\w+)"').allMatches(
    File('android/app/src/main/res/$folder/strings.xml').readAsStringSync(),
  ))
    match.group(1)!,
};

void main() {
  group('Russian translation', () {
    test('translates every message with the same placeholders', () {
      final english = _arb('app_en.arb');
      final russian = _arb('app_ru.arb');

      for (final MapEntry(:key, :value) in english.entries) {
        if (key.startsWith('@')) continue;
        expect(russian, contains(key), reason: 'missing Russian text for $key');
        expect(
          _placeholders(russian[key]! as String),
          _placeholders(value! as String),
          reason: 'placeholders differ for $key',
        );
      }
    });

    test('uses the Russian plural forms one, few and many', () {
      final russian = _arb('app_ru.arb');

      for (final MapEntry(:key, :value) in russian.entries) {
        if (key.startsWith('@') || value is! String) continue;
        if (!value.contains('plural,')) continue;
        for (final form in ['one{', 'few{', 'many{']) {
          expect(value, contains(form), reason: '$key lacks $form}');
        }
      }
    });

    testWidgets('shows Russian texts and plurals with a Russian locale', (
      tester,
    ) async {
      await tester.pumpApp(
        Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Column(
              children: [
                Text(l10n.beginFocus),
                Text(l10n.sessionsCount(1)),
                Text(l10n.sessionsCount(2)),
                Text(l10n.sessionsCount(5)),
              ],
            );
          },
        ),
        locale: const Locale('ru'),
      );

      expect(find.text('Начать фокус'), findsOneWidget);
      expect(find.text('1 сессия'), findsOneWidget);
      expect(find.text('2 сессии'), findsOneWidget);
      expect(find.text('5 сессий'), findsOneWidget);
    });

    test('translates every Android string', () {
      expect(_androidStrings('values-ru'), _androidStrings('values'));
    });
  });
}
