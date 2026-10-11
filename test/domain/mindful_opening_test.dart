import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/domain/focus_timer.dart';

import '../support/fake_block_list_repository.dart';
import '../support/fake_blocking_state_writer.dart';
import '../support/fake_session_repository.dart';
import '../support/fake_settings_repository.dart';

void main() {
  const telegram = 'org.telegram.messenger';
  const maps = 'com.google.android.apps.maps';
  // Monday, 2026-10-05.
  final now = DateTime(2026, 10, 5, 20);
  final blockList = const BlockList().add(telegram);
  final morning = FocusTime(
    id: 'focus-time-1',
    weekdays: const {1},
    startMinute: 8 * 60,
    endMinute: 12 * 60,
  );

  test('the pause lasts 5 seconds and an opened app stays free 5 minutes', () {
    expect(mindfulPause, const Duration(seconds: 5));
    expect(mindfulRelease, const Duration(minutes: 5));
  });

  test('the pause can be 3, 5, 10 or 20 seconds', () {
    expect(mindfulPauseOptions, const [
      Duration(seconds: 3),
      Duration(seconds: 5),
      Duration(seconds: 10),
      Duration(seconds: 20),
    ]);
  });

  group('BlockingState.from with mindful opening', () {
    test('keeps the default list without a session or focus time', () {
      expect(
        BlockingState.from(
          session: null,
          blockList: blockList,
          now: now,
          mindfulOpening: true,
          mindfulPackages: const {maps},
        ),
        const BlockingState(
          active: false,
          packageNames: {telegram},
          mindfulOpening: true,
          mindfulPackages: {maps},
        ),
      );
    });

    test('stays inactive without it and without anything to block', () {
      expect(
        BlockingState.from(session: null, blockList: blockList, now: now),
        const BlockingState.inactive(),
      );
    });
  });

  group('needsMindfulPause', () {
    final mindful = const BlockingState(
      active: false,
      packageNames: {telegram},
      mindfulOpening: true,
      mindfulPackages: {telegram},
    );

    bool check(
      BlockingState state, {
      String app = telegram,
      DateTime? at,
      DateTime? releasedUntil,
    }) => needsMindfulPause(
      state: state,
      packageName: app,
      now: at ?? now,
      releasedUntil: releasedUntil,
    );

    test('pauses a paused app outside sessions and focus times', () {
      expect(check(mindful), isTrue);
    });

    test('does not pause apps that are not on the mindful list', () {
      expect(check(mindful, app: maps), isFalse);
    });

    test('pauses only the mindful list, not the whole default list', () {
      const ownList = BlockingState(
        active: false,
        packageNames: {telegram, maps},
        mindfulOpening: true,
        mindfulPackages: {maps},
      );

      expect(check(ownList, app: telegram), isFalse);
      expect(check(ownList, app: maps), isTrue);
    });

    test('does not pause with the setting off', () {
      expect(
        check(const BlockingState(active: false, packageNames: {telegram})),
        isFalse,
      );
    });

    test('does not pause while released after opening', () {
      expect(
        check(mindful, releasedUntil: now.add(const Duration(minutes: 1))),
        isFalse,
      );
      expect(check(mindful, releasedUntil: now), isTrue);
    });

    test('leaves sessions strict: blocked, not paused', () {
      final session = BlockingState(
        active: true,
        packageNames: const {telegram},
        plannedEnd: now.add(const Duration(minutes: 20)),
        mindfulOpening: true,
        mindfulPackages: const {telegram},
      );

      expect(check(session), isFalse);
      expect(blocksAt(state: session, packageName: telegram, now: now), isTrue);
    });

    test('does not pause during a focus time', () {
      final focusTime = BlockingState(
        active: false,
        packageNames: const {telegram},
        focusTimes: [morning],
        mindfulOpening: true,
        mindfulPackages: const {telegram},
      );

      expect(check(focusTime, at: DateTime(2026, 10, 5, 9)), isFalse);
      expect(check(focusTime, at: DateTime(2026, 10, 5, 13)), isTrue);
    });
  });

  group('BlockingSync with mindful opening', () {
    test('writes the setting into the state', () async {
      final writer = FakeBlockingStateWriter();
      final settings = FakeSettingsRepository()..mindfulOpening = true;
      final timer = FocusTimer(
        repository: FakeSessionRepository(),
        clock: () => now,
        blocking: BlockingSync(
          blockList: FakeBlockListRepository(blockList),
          writer: writer,
          clock: () => now,
          settings: settings,
          mindfulApps: FakeBlockListRepository(const BlockList({maps})),
        ),
      );

      await timer.refreshBlocking();

      expect(writer.last?.mindfulOpening, isTrue);
      expect(writer.last?.packageNames, {telegram});
      expect(writer.last?.mindfulPackages, {maps});
    });
  });

  test('a finished session no longer blocks, so the pause applies again', () {
    final session = FocusSession(
      start: now.subtract(const Duration(minutes: 30)),
      planned: const Duration(minutes: 25),
    ).complete();

    expect(
      BlockingState.from(
        session: session,
        blockList: blockList,
        now: now,
        mindfulOpening: true,
      ).active,
      isFalse,
    );
  });
}
