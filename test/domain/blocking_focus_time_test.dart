import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_time.dart';

import '../support/fake_block_list_repository.dart';
import '../support/fake_blocking_state_writer.dart';
import '../support/fake_focus_time_repository.dart';

void main() {
  const telegram = 'org.telegram.messenger';
  const youtube = 'com.google.android.youtube';
  final blockList = const BlockList().add(telegram);
  // Weekdays 09:00–12:00; 2026-09-30 is a Wednesday.
  final mornings = FocusTime(
    id: 'focus-time-1',
    weekdays: const {1, 2, 3, 4, 5},
    startMinute: 9 * 60,
    endMinute: 12 * 60,
  );
  final inside = DateTime(2026, 9, 30, 10);
  final outside = DateTime(2026, 9, 30, 13);

  BlockingState stateWithFocusTimes(DateTime now) => BlockingState.from(
    session: null,
    blockList: blockList,
    now: now,
    focusTimes: [mornings],
  );

  group('BlockingState.from with focus times', () {
    test('keeps the block list and focus times without a session', () {
      final state = stateWithFocusTimes(outside);

      expect(state.active, isFalse);
      expect(state.packageNames, {telegram});
      expect(state.focusTimes, [mornings]);
    });

    test('stays inactive without session and focus times', () {
      expect(
        BlockingState.from(
          session: null,
          blockList: blockList,
          now: outside,
          focusTimes: const [],
        ),
        const BlockingState.inactive(),
      );
    });
  });

  group('blocksAt', () {
    test('blocks listed apps during a focus time without a session', () {
      final state = stateWithFocusTimes(inside);

      expect(
        blocksAt(state: state, packageName: telegram, now: inside),
        isTrue,
      );
    });

    test('does not block outside focus times or unlisted apps', () {
      final state = stateWithFocusTimes(inside);

      expect(
        blocksAt(state: state, packageName: telegram, now: outside),
        isFalse,
      );
      expect(
        blocksAt(state: state, packageName: youtube, now: inside),
        isFalse,
      );
    });

    test('blocks listed apps while a session is active', () {
      final session = FocusSession(
        start: outside,
        planned: const Duration(minutes: 25),
      );
      final state = BlockingState.from(
        session: session,
        blockList: blockList,
        now: outside,
      );

      expect(
        blocksAt(state: state, packageName: telegram, now: outside),
        isTrue,
      );
      expect(
        blocksAt(
          state: state,
          packageName: telegram,
          now: outside.add(const Duration(minutes: 25)),
        ),
        isFalse,
      );
    });
  });

  group('snoozeFor during focus times', () {
    test('holds back for at most a minute per round', () {
      expect(
        snoozeFor(
          state: stateWithFocusTimes(inside),
          packageName: telegram,
          now: inside,
        ),
        notificationSnoozeStep,
      );
    });

    test('never beyond the end of the focus time', () {
      final now = DateTime(2026, 9, 30, 11, 59, 30);

      expect(
        snoozeFor(
          state: stateWithFocusTimes(now),
          packageName: telegram,
          now: now,
        ),
        const Duration(seconds: 30),
      );
    });

    test('shows notifications outside focus times', () {
      expect(
        snoozeFor(
          state: stateWithFocusTimes(outside),
          packageName: telegram,
          now: outside,
        ),
        isNull,
      );
    });
  });

  group('BlockingSync with focus times', () {
    test('publishes the focus times from the repository', () async {
      final writer = FakeBlockingStateWriter();
      final sync = BlockingSync(
        blockList: FakeBlockListRepository(blockList),
        writer: writer,
        clock: () => outside,
        focusTimes: FakeFocusTimeRepository([mornings]),
      );

      await sync.update(null);

      expect(writer.last?.focusTimes, [mornings]);
      expect(writer.last?.packageNames, {telegram});
    });
  });
}
