import 'block_list_repository.dart';
import 'clock.dart';
import 'focus_session.dart';
import 'focus_time.dart';
import 'focus_time_repository.dart';

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
    this.focusTimes = const [],
  });

  const BlockingState.inactive()
    : active = false,
      packageNames = const {},
      plannedEnd = null,
      focusTimes = const [];

  /// Derives the state from the active session; [plannedEnd] is null while
  /// paused because the end is not known then. With [focusTimes] the block
  /// list is kept even without a session, so the native side can block
  /// during focus times on its own.
  factory BlockingState.from({
    required FocusSession? session,
    required BlockList blockList,
    required DateTime now,
    List<FocusTime> focusTimes = const [],
  }) {
    if (session == null || session.isFinished) {
      if (focusTimes.isEmpty) return const BlockingState.inactive();
      return BlockingState(
        active: false,
        packageNames: blockList.packageNames,
        focusTimes: focusTimes,
      );
    }
    return BlockingState(
      active: true,
      packageNames: blockList.packageNames,
      plannedEnd: session.isPaused ? null : now.add(session.remaining(now)),
      focusTimes: focusTimes,
    );
  }

  /// Whether a session is running or paused.
  final bool active;
  final Set<String> packageNames;
  final DateTime? plannedEnd;

  /// Recurring focus times during which [packageNames] are blocked as well.
  final List<FocusTime> focusTimes;

  @override
  bool operator ==(Object other) =>
      other is BlockingState &&
      other.active == active &&
      other.plannedEnd == plannedEnd &&
      _sameFocusTimes(other.focusTimes, focusTimes) &&
      other.packageNames.length == packageNames.length &&
      other.packageNames.containsAll(packageNames);

  @override
  int get hashCode => Object.hash(
    active,
    plannedEnd,
    Object.hashAllUnordered(packageNames),
    Object.hashAll(focusTimes),
  );
}

bool _sameFocusTimes(List<FocusTime> a, List<FocusTime> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Whether [packageName] must be blocked at [now]: while a session is
/// active or during a focus time, and only for listed apps. Mirrored in
/// Kotlin (`BlockingState.blocks`).
bool blocksAt({
  required BlockingState state,
  required String packageName,
  required DateTime now,
}) {
  if (!state.packageNames.contains(packageName)) return false;
  final end = state.plannedEnd;
  final sessionBlocks = state.active && (end == null || now.isBefore(end));
  return sessionBlocks || activeFocusTime(state.focusTimes, now) != null;
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
    this._focusTimes,
  });

  final BlockListRepository _blockList;
  final BlockingStateWriter _writer;
  final Clock _clock;
  final FocusTimeRepository? _focusTimes;

  Future<void> update(FocusSession? session) async {
    final blockList = await _blockList.loadBlockList();
    final focusTimes = await _focusTimes?.watchFocusTimes().first;
    await _writer.write(
      BlockingState.from(
        session: session,
        blockList: blockList,
        now: _clock(),
        focusTimes: focusTimes ?? const [],
      ),
    );
  }
}

/// Longest snooze per round: notifications of paused apps are snoozed in
/// short rounds, so they reappear within a minute once the session ends –
/// also when it ends early.
const notificationSnoozeStep = Duration(minutes: 1);

/// How long to hold back a notification of [packageName] at [now] (during a
/// session or a focus time), or null if it may be shown. Mirrored in Kotlin
/// (`BlockingState.snoozeMillis`).
Duration? snoozeFor({
  required BlockingState state,
  required String packageName,
  required DateTime now,
}) {
  if (!state.packageNames.contains(packageName)) return null;
  if (state.active) {
    final end = state.plannedEnd;
    if (end == null) return notificationSnoozeStep;
    final left = end.difference(now);
    if (left > Duration.zero) {
      return left < notificationSnoozeStep ? left : notificationSnoozeStep;
    }
  }
  final focusTime = activeFocusTime(state.focusTimes, now);
  if (focusTime == null) return null;
  final left = focusTime.endOn(now).difference(now);
  return left < notificationSnoozeStep ? left : notificationSnoozeStep;
}
