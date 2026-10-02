import 'dart:async';

import 'package:focus_timer/domain/app_blocker.dart';

/// Controllable [AppBlocker] for tests.
class FakeAppBlocker implements AppBlocker {
  FakeAppBlocker({
    this.enabled = true,
    this.notificationGateEnabled = true,
    this.initial,
  });

  bool enabled;
  bool notificationGateEnabled;
  var openedNotificationSettings = 0;
  String? initial;
  var openedSettings = 0;
  var openedAppInfo = 0;
  final _opened = StreamController<String>.broadcast();

  /// Simulates the user opening a blocked app while Focus runs.
  void emit(String packageName) => _opened.add(packageName);

  @override
  Future<bool> isBlockerEnabled() async => enabled;

  @override
  Future<void> openBlockerSettings() async => openedSettings++;

  @override
  Future<bool> isNotificationGateEnabled() async => notificationGateEnabled;

  @override
  Future<void> openNotificationGateSettings() async =>
      openedNotificationSettings++;

  @override
  Future<void> openAppInfo() async => openedAppInfo++;

  @override
  Future<String?> initialBlockedPackage() async {
    final package = initial;
    initial = null;
    return package;
  }

  @override
  Stream<String> get blockedAppOpened => _opened.stream;
}
