import 'package:flutter/services.dart';

import '../domain/blocking.dart';
import '../domain/installed_apps_source.dart';

/// Reads the installed launcher apps from the Android side (`MainActivity`).
class MethodChannelInstalledAppsSource implements InstalledAppsSource {
  const MethodChannelInstalledAppsSource();

  static const channel = MethodChannel('de.maestrodev.focus_timer/apps');

  @override
  Future<List<InstalledApp>> installedApps() async {
    final entries = await channel.invokeListMethod<Object?>('installedApps');
    return [
      for (final entry in entries ?? const <Object?>[])
        switch (entry) {
          {
            'packageName': final String packageName,
            'label': final String label,
          } =>
            InstalledApp(packageName: packageName, label: label),
          _ => throw FormatException('Malformed installed app: $entry'),
        },
    ];
  }

  @override
  Future<Uint8List?> iconOf(String packageName) =>
      channel.invokeMethod<Uint8List>('appIcon', packageName);
}
