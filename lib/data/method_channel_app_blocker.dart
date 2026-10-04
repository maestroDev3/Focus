import 'dart:async';

import 'package:flutter/services.dart';

import '../domain/app_blocker.dart';

/// Talks to `MainActivity` and `FocusBlockerService` on Android.
class MethodChannelAppBlocker implements AppBlocker {
  MethodChannelAppBlocker() {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'blockedAppOpened' && call.arguments is String) {
        _opened.add(call.arguments as String);
      }
      if (call.method == 'mindfulOpenRequested') {
        if (_mindfulRequest(call.arguments) case final request?) {
          _mindful.add(request);
        }
      }
    });
  }

  static const channel = MethodChannel('de.maestrodev.focus_timer/blocking');

  final _opened = StreamController<String>.broadcast();
  final _mindful = StreamController<MindfulRequest>.broadcast();

  /// `{package, openedToday}` from the native side, or null if malformed.
  static MindfulRequest? _mindfulRequest(Object? arguments) =>
      switch (arguments) {
        {'package': final String package, 'openedToday': final int count} =>
          MindfulRequest(packageName: package, openedToday: count),
        _ => null,
      };

  @override
  Future<bool> isBlockerEnabled() async =>
      await channel.invokeMethod<bool>('isBlockerEnabled') ?? false;

  @override
  Future<void> openBlockerSettings() =>
      channel.invokeMethod<void>('openBlockerSettings');

  @override
  Future<bool> isNotificationGateEnabled() async =>
      await channel.invokeMethod<bool>('isNotificationGateEnabled') ?? false;

  @override
  Future<void> openNotificationGateSettings() =>
      channel.invokeMethod<void>('openNotificationGateSettings');

  @override
  Future<void> openAppInfo() => channel.invokeMethod<void>('openAppInfo');

  @override
  Future<String?> initialBlockedPackage() =>
      channel.invokeMethod<String>('initialBlockedPackage');

  @override
  Stream<String> get blockedAppOpened => _opened.stream;

  @override
  Future<MindfulRequest?> initialMindfulRequest() async => _mindfulRequest(
    await channel.invokeMethod<Object?>('initialMindfulRequest'),
  );

  @override
  Stream<MindfulRequest> get mindfulOpenRequested => _mindful.stream;

  @override
  Future<void> openMindfully(String packageName) =>
      channel.invokeMethod<void>('openMindfully', packageName);

  @override
  Future<void> goHome() => channel.invokeMethod<void>('goHome');
}
