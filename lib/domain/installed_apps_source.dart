import 'dart:typed_data';

import 'blocking.dart';

/// Lists the apps on the phone the user can choose to block.
abstract interface class InstalledAppsSource {
  /// Apps with a launcher entry, sorted by name, without Focus itself.
  Future<List<InstalledApp>> installedApps();

  /// The app's launcher icon as PNG, or null if it has none.
  Future<Uint8List?> iconOf(String packageName);
}
