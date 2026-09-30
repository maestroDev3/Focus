import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_timer.dart';

import '../support/fake_block_list_repository.dart';
import '../support/fake_blocking_state_writer.dart';
import '../support/fake_session_repository.dart';

void main() {
  const telegram = 'org.telegram.messenger';
  const youtube = 'com.google.android.youtube';
  final start = DateTime(2026, 9, 30, 10);
  final blockList = const BlockList().add(telegram);
  FocusSession running() =>
      FocusSession(start: start, planned: const Duration(minutes: 25));

  group('shouldBlock', () {
    bool check(String app, FocusSession? session) => shouldBlock(
      packageName: app,
      blockList: blockList,
      activeSession: session,
    );

    test('blocks listed apps while a session runs or is paused', () {
      expect(check(telegram, running()), isTrue);
      expect(check(telegram, running().pause(start)), isTrue);
    });

    test('does not block other apps', () {
      expect(check(youtube, running()), isFalse);
    });

    test('does not block without a session or after it ended', () {
      expect(check(telegram, null), isFalse);
      expect(check(telegram, running().cancel(start)), isFalse);
      expect(check(telegram, running().complete()), isFalse);
    });
  });

  group('BlockingState.from', () {
    test('is active with the planned end while running', () {
      final now = start.add(const Duration(minutes: 5));

      expect(
        BlockingState.from(session: running(), blockList: blockList, now: now),
        BlockingState(
          active: true,
          packageNames: const {telegram},
          plannedEnd: start.add(const Duration(minutes: 25)),
        ),
      );
    });

    test('is active without an end while paused', () {
      final now = start.add(const Duration(minutes: 5));
      final state = BlockingState.from(
        session: running().pause(now),
        blockList: blockList,
        now: now,
      );

      expect(state.active, isTrue);
      expect(state.plannedEnd, isNull);
    });

    test('is inactive without a session or after it ended', () {
      expect(
        BlockingState.from(session: null, blockList: blockList, now: start),
        const BlockingState.inactive(),
      );
      expect(
        BlockingState.from(
          session: running().cancel(start),
          blockList: blockList,
          now: start,
        ),
        const BlockingState.inactive(),
      );
    });
  });

  group('FocusTimer with BlockingSync', () {
    late DateTime now;
    late FakeBlockingStateWriter writer;
    late FocusTimer timer;

    setUp(() {
      now = start;
      writer = FakeBlockingStateWriter();
      timer = FocusTimer(
        repository: FakeSessionRepository(),
        clock: () => now,
        blocking: BlockingSync(
          blockList: FakeBlockListRepository(blockList),
          writer: writer,
          clock: () => now,
        ),
      );
    });

    test('writes the state on start, pause and end', () async {
      await timer.start(const Duration(minutes: 25));
      expect(writer.last?.active, isTrue);
      expect(writer.last?.plannedEnd, start.add(const Duration(minutes: 25)));
      expect(writer.last?.packageNames, {telegram});

      now = now.add(const Duration(minutes: 5));
      await timer.pause();
      expect(writer.last?.active, isTrue);
      expect(writer.last?.plannedEnd, isNull);

      await timer.cancel();
      expect(writer.last, const BlockingState.inactive());
    });
  });
}
