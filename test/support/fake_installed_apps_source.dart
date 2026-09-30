import 'dart:convert';
import 'dart:typed_data';

import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/installed_apps_source.dart';

/// Fixed list of installed apps for tests; YouTube has no icon.
class FakeInstalledAppsSource implements InstalledAppsSource {
  FakeInstalledAppsSource([this.apps = sampleApps]);

  static const sampleApps = [
    InstalledApp(packageName: 'com.instagram.android', label: 'Instagram'),
    InstalledApp(packageName: 'org.telegram.messenger', label: 'Telegram'),
    InstalledApp(packageName: 'com.google.android.youtube', label: 'YouTube'),
  ];

  /// A valid 1×1 transparent PNG.
  static final samplePng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
    '60e6kgAAAABJRU5ErkJggg==',
  );

  final List<InstalledApp> apps;

  @override
  Future<List<InstalledApp>> installedApps() async => apps;

  @override
  Future<Uint8List?> iconOf(String packageName) async =>
      packageName == 'com.google.android.youtube' ? null : samplePng;
}
