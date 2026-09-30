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
    });
  }

  static const channel = MethodChannel('de.maestrodev.focus_timer/blocking');

  final _opened = StreamController<String>.broadcast();

  @override
  Future<bool> isBlockerEnabled() async =>
      await channel.invokeMethod<bool>('isBlockerEnabled') ?? false;

  @override
  Future<void> openBlockerSettings() =>
      channel.invokeMethod<void>('openBlockerSettings');

  @override
  Future<String?> initialBlockedPackage() =>
      channel.invokeMethod<String>('initialBlockedPackage');

  @override
  Stream<String> get blockedAppOpened => _opened.stream;
}
