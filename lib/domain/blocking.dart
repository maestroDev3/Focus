import 'block_list_repository.dart';
import 'clock.dart';
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

/// Whether [packageName] must be blocked right now: only while a session
/// runs or is paused, and only for apps on the block list.
bool shouldBlock({
  required String packageName,
  required BlockList blockList,
  required FocusSession? activeSession,
}) {
  return activeSession != null &&
      !activeSession.isFinished &&
      blockList.contains(packageName);
}

/// What the native blocker needs to know, even while Flutter is not running.
class BlockingState {
  const BlockingState({
    required this.active,
    required this.packageNames,
    this.plannedEnd,
  });

  const BlockingState.inactive()
    : active = false,
      packageNames = const {},
      plannedEnd = null;

  /// Derives the state from the active session; [plannedEnd] is null while
  /// paused because the end is not known then.
  factory BlockingState.from({
    required FocusSession? session,
    required BlockList blockList,
    required DateTime now,
  }) {
    if (session == null || session.isFinished) {
      return const BlockingState.inactive();
    }
    return BlockingState(
      active: true,
      packageNames: blockList.packageNames,
      plannedEnd: session.isPaused ? null : now.add(session.remaining(now)),
    );
  }

  final bool active;
  final Set<String> packageNames;
  final DateTime? plannedEnd;

  @override
  bool operator ==(Object other) =>
      other is BlockingState &&
      other.active == active &&
      other.plannedEnd == plannedEnd &&
      other.packageNames.length == packageNames.length &&
      other.packageNames.containsAll(packageNames);

  @override
  int get hashCode =>
      Object.hash(active, plannedEnd, Object.hashAllUnordered(packageNames));
}

/// Publishes the [BlockingState] where the native blocker can read it.
abstract interface class BlockingStateWriter {
  Future<void> write(BlockingState state);
}

/// Writes a fresh [BlockingState] whenever the session or block list changes.
class BlockingSync {
  BlockingSync({
    required this._blockList,
    required this._writer,
    required this._clock,
  });

  final BlockListRepository _blockList;
  final BlockingStateWriter _writer;
  final Clock _clock;

  Future<void> update(FocusSession? session) async {
    final blockList = await _blockList.loadBlockList();
    await _writer.write(
      BlockingState.from(session: session, blockList: blockList, now: _clock()),
    );
  }
}

/// Longest snooze per round: notifications of paused apps are snoozed in
/// short rounds, so they reappear within a minute once the session ends –
/// also when it ends early.
const notificationSnoozeStep = Duration(minutes: 1);

/// How long to hold back a notification of [packageName] at [now], or null
/// if it may be shown. Mirrored in Kotlin (`BlockingState.snoozeMillis`).
Duration? snoozeFor({
  required BlockingState state,
  required String packageName,
  required DateTime now,
}) {
  if (!state.active || !state.packageNames.contains(packageName)) return null;
  final end = state.plannedEnd;
  if (end == null) return notificationSnoozeStep;
  final left = end.difference(now);
  if (left <= Duration.zero) return null;
  return left < notificationSnoozeStep ? left : notificationSnoozeStep;
}
