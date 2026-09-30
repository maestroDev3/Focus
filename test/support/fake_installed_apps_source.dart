import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/installed_apps_source.dart';

/// Fixed list of installed apps for tests.
class FakeInstalledAppsSource implements InstalledAppsSource {
  FakeInstalledAppsSource([this.apps = sampleApps]);

  static const sampleApps = [
    InstalledApp(packageName: 'com.instagram.android', label: 'Instagram'),
    InstalledApp(packageName: 'org.telegram.messenger', label: 'Telegram'),
    InstalledApp(packageName: 'com.google.android.youtube', label: 'YouTube'),
  ];

  final List<InstalledApp> apps;

  @override
  Future<List<InstalledApp>> installedApps() async => apps;
}
