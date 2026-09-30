import 'dart:async';

import 'package:focus_timer/domain/app_blocker.dart';

/// Controllable [AppBlocker] for tests.
class FakeAppBlocker implements AppBlocker {
  FakeAppBlocker({this.enabled = true, this.initial});

  bool enabled;
  String? initial;
  var openedSettings = 0;
  final _opened = StreamController<String>.broadcast();

  /// Simulates the user opening a blocked app while Focus runs.
  void emit(String packageName) => _opened.add(packageName);

  @override
  Future<bool> isBlockerEnabled() async => enabled;

  @override
  Future<void> openBlockerSettings() async => openedSettings++;

  @override
  Future<String?> initialBlockedPackage() async {
    final package = initial;
    initial = null;
    return package;
  }

  @override
  Stream<String> get blockedAppOpened => _opened.stream;
}
