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
  final _mindful = StreamController<MindfulRequest>.broadcast();

  /// The mindful request Focus was launched for (consumed once).
  MindfulRequest? initialMindful;

  /// Apps opened after the breathing pause.
  final openedMindfully = <String>[];
  var wentHome = 0;

  /// Simulates opening a paused app with mindful opening on.
  void emitMindful(MindfulRequest request) => _mindful.add(request);

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

  @override
  Future<MindfulRequest?> initialMindfulRequest() async {
    final request = initialMindful;
    initialMindful = null;
    return request;
  }

  @override
  Stream<MindfulRequest> get mindfulOpenRequested => _mindful.stream;

  @override
  Future<void> openMindfully(String packageName) async =>
      openedMindfully.add(packageName);

  @override
  Future<void> goHome() async => wentHome++;
}
