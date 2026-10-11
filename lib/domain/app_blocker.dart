/// A paused app opened outside sessions and focus times with mindful
/// opening on: Focus shows the breathing pause first.
class MindfulRequest {
  const MindfulRequest({required this.packageName, required this.openedToday});

  final String packageName;

  /// How often the app was opened today, this time included.
  final int openedToday;

  @override
  bool operator ==(Object other) =>
      other is MindfulRequest &&
      other.packageName == packageName &&
      other.openedToday == openedToday;

  @override
  int get hashCode => Object.hash(packageName, openedToday);
}

/// The native app blocker (Android accessibility service) as seen by the app.
abstract interface class AppBlocker {
  /// Whether the user enabled the blocker in the accessibility settings.
  Future<bool> isBlockerEnabled();

  /// Opens the system settings where the blocker can be enabled.
  Future<void> openBlockerSettings();

  /// Whether the user granted notification access (holding notifications).
  Future<bool> isNotificationGateEnabled();

  /// Opens the system settings for notification access.
  Future<void> openNotificationGateSettings();

  /// Opens Focus' app info page, where Android lets the user allow
  /// restricted settings for apps installed outside the Play Store.
  Future<void> openAppInfo();

  /// The blocked app Focus was launched for, if any (consumed once).
  Future<String?> initialBlockedPackage();

  /// Blocked apps the user tried to open while Focus was running.
  Stream<String> get blockedAppOpened;

  /// The mindful request Focus was launched for, if any (consumed once).
  Future<MindfulRequest?> initialMindfulRequest();

  /// Paused apps opened with mindful opening on while Focus was running.
  Stream<MindfulRequest> get mindfulOpenRequested;

  /// Opens [packageName] after the pause; it stays free for
  /// `mindfulRelease`.
  Future<void> openMindfully(String packageName);

  /// Leaves the paused app: shows the home screen.
  Future<void> goHome();
}
