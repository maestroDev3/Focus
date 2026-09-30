import 'blocking.dart';

/// Lists the apps on the phone the user can choose to block.
abstract interface class InstalledAppsSource {
  /// Apps with a launcher entry, sorted by name, without Focus itself.
  Future<List<InstalledApp>> installedApps();
}
