---
name: flutter-dart
description: Binding Flutter/Dart conventions for the Focus app (architecture, state, Dart style, widgets, localization, tests, definition of done). Use whenever creating or changing .dart files, tests, ARB files, pubspec.yaml or Android configuration in this repo.
---

# Flutter/Dart – conventions for Focus

Sources: the official Flutter AI `rules.md`, Effective Dart, the Flutter App
Architecture Guide, VGV skills. Only what applies to this project or deliberately
deviates is written here. On conflict: user > CLAUDE.md > this skill.

## 1. Architecture (layers)

| Folder | Content | May import |
|---|---|---|
| `lib/domain` | Models, pure logic, repository **interfaces** | only `dart:` and `lib/domain` – **no** `package:flutter` |
| `lib/data` | Repository implementations, platform services (storage, notifications) | `lib/domain`, packages |
| `lib/ui` | Screens and widgets | `lib/domain`, `package:flutter`, generated l10n – **never** `lib/data` directly |
| `lib/l10n` | ARB files (`app_en.arb` is the template) | – |
| `lib/main.dart` | Wiring: create instances, pass them via constructors | everything |

- Repositories are the single source of data; they return `Future`/`Stream` and don't know about each other.
- Platform APIs (plugins) only behind an interface in `lib/domain` (e.g. `NotificationScheduler`), implementation in `lib/data`.
- Time always comes via `Clock` (`typedef Clock = DateTime Function()`) or a `today`/`now` parameter. No `DateTime.now()` in `lib/domain` or widgets except as default argument `clock = DateTime.now`.
- Days are normalized with `dayOf()` (UTC midnight) so daylight saving time never shifts days.

## 2. State

- No state management package (no provider/riverpod/bloc/get_it), no code generation except Flutter's built-in `gen-l10n` (no freezed/build_runner), navigation with `Navigator` (no go_router).
- Showing data: `StreamBuilder` over repository streams. Local UI state: `StatefulWidget` or `ValueNotifier`.
- If logic in a widget grows beyond a few lines, it moves to `lib/domain` as a pure function/class (testable without widgets).
- After every `await` in a `State`, check `mounted` before `setState`/`context`.

## 3. Dart style

- Names: types `UpperCamelCase`, files `lower_snake_case.dart`, everything else `lowerCamelCase` (constants too). No abbreviations.
- **Everything in English**: identifiers, comments, UI texts. Doc comments `///` start with a sentence stating the *why*/purpose.
- Domain models are immutable: `final` fields, `const` constructor where possible, changes via `copyWith`/methods returning a new instance.
- Variants as `sealed class` + exhaustive `switch`. Multiple return values as records.
- No `!` on nullable values – use patterns (`case final x?`) or early `return`.
- No positional `bool` parameters; use named parameters.
- Invalid input in the domain: `ArgumentError`; state errors: `StateError`. Never swallow silently.
- Imports: `dart:` → `package:` → relative; inside `lib/` relative imports, in tests `package:focus_timer/...`.
- Formatting is decided by `dart format`; `flutter analyze` (flutter_lints) must report nothing.

## 4. Widgets, design and localization

- Sub-UIs as small private widget classes (`_WeekRow`), no methods returning widgets (exception: short `switch` expressions).
- `const` wherever possible; nothing expensive in `build()`; lists via `ListView.builder`/`SliverList.builder`.
- Colors and text styles only from `Theme.of(context)` (`colorScheme`, `textTheme`) – no hex values in widgets. Theme in `lib/ui/theme.dart`, light and dark.
- Material 3; consistent patterns: cards (`Card`), `SliverAppBar.large`, bottom sheets with `showDragHandle`, `FilledButton`/`OutlinedButton`. Recurring building blocks as widgets in `lib/ui/widgets/`.
- **No hard-coded UI strings.** Every visible text comes from `AppLocalizations` (ARB key in `app_en.arb` with `@description`). Plurals and placeholders via ICU syntax. Dates, numbers and currency formatted with `intl` using the current locale.
- Icon buttons get a `tooltip` (also serves as semantics label).
- Texts must be allowed to wrap with large system fonts (no fixed `height` for text containers).

## 5. Tests (TDD is mandatory, see CLAUDE.md)

- Structure mirrors `lib/`: `test/domain`, `test/data`, `test/ui`. Test helpers in `test/support/` (no `_test.dart` suffix).
- Fakes instead of mocks (no mockito/mocktail): `Fake<Name>Repository`, `FakeNotificationScheduler`. New interfaces get a fake in `test/support/`.
- Fixed times: tests define `today`/`now` as constants and pass them in; never depend on the real clock.
- Layout: one `group` per class/function or behavior, `test` descriptions as English sentences (“keeps the streak with a joker”). Arrange – Act – Assert.
- Widget tests: `pumpApp` from `test/support/pump_app.dart` (sets theme, localization delegates with `en` locale and phone size); find widgets by visible text or `Key`, not by widget hierarchy.
- Every acceptance criterion of the issue has at least one test. Platform code that can only be checked on a device gets a “test manually” note in the PR.

## 6. Dependencies and Android

- Standard base packages without further justification: `shared_preferences` or `sqflite` (storage), `path_provider`, `flutter_local_notifications` + `timezone` + `flutter_timezone`, `flutter_localizations` + `intl`.
- Other packages only with justification in the PR; check the version first (`git ls-remote --tags` of the package repo, pub.dev is blocked in Claude's environment).
- Mark PRs with Android changes (manifest, Gradle, plugins with native code) with `[apk]` in the PR title so CI builds the APK for the PR.
- No permission without a purpose; justify every new permission in the PR. No `INTERNET` unless a decision requires it.

## 7. Definition of done (per task)

- [ ] Test commit red in CI, then green
- [ ] `flutter analyze` clean, `dart format` compliant
- [ ] Domain free of Flutter imports, time via Clock/parameter
- [ ] Stored data backward compatible (old data still loads – migration test)
- [ ] UI texts in ARB files (English), theme colors, tooltips on icon buttons
- [ ] PR with `Closes #nr`, what/why/tests

## 8. Common mistakes

| Don't | Do |
|---|---|
| `DateTime.now()` in logic | `clock()` / `today` parameter |
| Logic in `build()` or `onPressed` | pure function in `lib/domain` |
| `setState` after `await` without `mounted` | `if (!mounted) return;` |
| Widget imports `lib/data/...` | interface from `lib/domain` via constructor |
| `Text('Save')` | `Text(AppLocalizations.of(context).save)` |
| `print` for debugging | write a test; errors as exceptions |
| New storage format without migration | version the keys, read the old one, test it |
| `Color(0xFF…)` in a widget | `Theme.of(context).colorScheme…` |

## 9. Project-specific: Focus

- The timer **never** counts ticks. Store start time, planned duration and pauses; remaining time is `remaining(session, now)` – a pure function. That way a session survives app kill and restart.
- The UI refreshes via `Stream.periodic`/`Ticker` that only repaints; logic stays in the domain.
- Statistics are **derived** from stored sessions, never counted separately (single source of truth).
- Minimal, calm design: lots of whitespace, one accent color, no gamification elements.
- Animations via implicit animations (`AnimatedContainer`, `TweenAnimationBuilder`); tests use `pumpAndSettle` or fixed `pump(Duration)`.