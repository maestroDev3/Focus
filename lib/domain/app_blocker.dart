/// The native app blocker (Android accessibility service) as seen by the app.
abstract interface class AppBlocker {
  /// Whether the user enabled the blocker in the accessibility settings.
  Future<bool> isBlockerEnabled();

  /// Opens the system settings where the blocker can be enabled.
  Future<void> openBlockerSettings();

  /// The blocked app Focus was launched for, if any (consumed once).
  Future<String?> initialBlockedPackage();

  /// Blocked apps the user tried to open while Focus was running.
  Stream<String> get blockedAppOpened;
}
