import 'focus_session.dart';

/// Android package name of Focus itself, which can never be blocked.
const focusPackageName = 'de.maestrodev.focus_timer';

/// An app installed on the phone that can be put on the block list.
class InstalledApp {
  const InstalledApp({required this.packageName, required this.label});

  final String packageName;
  final String label;

  @override
  bool operator ==(Object other) =>
      other is InstalledApp &&
      other.packageName == packageName &&
      other.label == label;

  @override
  int get hashCode => Object.hash(packageName, label);
}

/// The apps the user chose to pause while focusing.
class BlockList {
  const BlockList([this.packageNames = const {}]);

  final Set<String> packageNames;

  int get length => packageNames.length;

  bool contains(String packageName) => packageNames.contains(packageName);

  BlockList add(String packageName) {
    if (packageName == focusPackageName) {
      throw ArgumentError.value(packageName, 'packageName', 'is Focus itself');
    }
    return BlockList({...packageNames, packageName});
  }

  BlockList remove(String packageName) =>
      BlockList({...packageNames}..remove(packageName));

  @override
  bool operator ==(Object other) =>
      other is BlockList &&
      other.packageNames.length == packageNames.length &&
      other.packageNames.containsAll(packageNames);

  @override
  int get hashCode => Object.hashAllUnordered(packageNames);
}

/// Strict mode: while a session runs or is paused, apps can be added to the
/// block list but not removed.
bool canRemoveFromBlockList({required FocusSession? activeSession}) =>
    activeSession == null || activeSession.isFinished;
