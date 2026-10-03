import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_session.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:focus_timer/domain/named_block_list.dart';

import '../support/fake_block_list_repository.dart';
import '../support/fake_blocking_state_writer.dart';
import '../support/fake_focus_time_repository.dart';
import '../support/fake_named_block_list_repository.dart';

void main() {
  const telegram = 'org.telegram.messenger';
  const instagram = 'com.instagram.android';
  const youtube = 'com.google.android.youtube';
  final nineOClock = DateTime(2026, 10, 5, 9); // Monday
  FocusTime morning({String? blockListId}) => FocusTime(
    id: 'focus-time-1',
    weekdays: const {1, 2, 3, 4, 5, 6, 7},
    startMinute: 8 * 60,
    endMinute: 10 * 60,
    blockListId: blockListId,
  );

  group('blocksAt with a focus time list', () {
    test('blocks only the apps of the focus time list', () {
      final state = BlockingState(
        active: false,
        packageNames: const {telegram, instagram},
        focusTimes: [morning(blockListId: 'list-1')],
        focusTimePackages: const {
          'focus-time-1': {instagram, youtube},
        },
      );

      expect(
        blocksAt(state: state, packageName: telegram, now: nineOClock),
        isFalse,
      );
      expect(
        blocksAt(state: state, packageName: youtube, now: nineOClock),
        isTrue,
      );
    });

    test('uses the default list for a focus time without own list', () {
      final state = BlockingState(
        active: false,
        packageNames: const {telegram},
        focusTimes: [morning()],
      );

      expect(
        blocksAt(state: state, packageName: telegram, now: nineOClock),
        isTrue,
      );
    });

    test('blocks both lists when a session runs during the focus time', () {
      final state = BlockingState(
        active: true,
        packageNames: const {telegram},
        plannedEnd: nineOClock.add(const Duration(minutes: 20)),
        focusTimes: [morning(blockListId: 'list-1')],
        focusTimePackages: const {
          'focus-time-1': {instagram},
        },
      );

      expect(
        blocksAt(state: state, packageName: telegram, now: nineOClock),
        isTrue,
      );
      expect(
        blocksAt(state: state, packageName: instagram, now: nineOClock),
        isTrue,
      );
    });
  });

  group('snoozeFor with a focus time list', () {
    test('lets notifications of apps outside the focus time list through', () {
      final state = BlockingState(
        active: false,
        packageNames: const {telegram, instagram},
        focusTimes: [morning(blockListId: 'list-1')],
        focusTimePackages: const {
          'focus-time-1': {instagram},
        },
      );

      expect(
        snoozeFor(state: state, packageName: telegram, now: nineOClock),
        isNull,
      );
      expect(
        snoozeFor(state: state, packageName: instagram, now: nineOClock),
        notificationSnoozeStep,
      );
    });
  });

  group('BlockingSync with named lists', () {
    test('publishes the apps of each focus time list', () async {
      final writer = FakeBlockingStateWriter();
      final sync = BlockingSync(
        blockList: FakeBlockListRepository(const BlockList().add(telegram)),
        writer: writer,
        clock: () => nineOClock,
        focusTimes: FakeFocusTimeRepository([
          morning(blockListId: 'list-1'),
          FocusTime(
            id: 'focus-time-2',
            weekdays: const {1},
            startMinute: 17 * 60,
            endMinute: 21 * 60,
            blockListId: 'deleted-list',
          ),
        ]),
        namedLists: FakeNamedBlockListRepository([
          NamedBlockList(
            id: 'list-1',
            name: 'Morning',
            apps: const BlockList().add(instagram),
          ),
        ]),
      );

      await sync.update(null);

      expect(writer.last?.focusTimePackages, {
        'focus-time-1': {instagram},
      });
    });
  });

  group('isBlockListInUse', () {
    final session = FocusSession(
      start: nineOClock,
      planned: const Duration(minutes: 25),
    );

    test('the default list is used by sessions and plain focus times', () {
      expect(isBlockListInUse(listId: null, activeSession: session), isTrue);
      expect(
        isBlockListInUse(listId: null, activeFocusTime: morning()),
        isTrue,
      );
      expect(
        isBlockListInUse(
          listId: null,
          activeFocusTime: morning(blockListId: 'list-1'),
        ),
        isFalse,
      );
      expect(isBlockListInUse(listId: null), isFalse);
    });

    test('a named list is used by the running focus time using it', () {
      expect(
        isBlockListInUse(
          listId: 'list-1',
          activeFocusTime: morning(blockListId: 'list-1'),
        ),
        isTrue,
      );
      expect(
        isBlockListInUse(listId: 'list-1', activeSession: session),
        isFalse,
      );
    });
  });

  group('FocusTime.blockListId', () {
    test('is part of equality', () {
      expect(morning(blockListId: 'list-1'), isNot(morning()));
      expect(morning(blockListId: 'list-1'), morning(blockListId: 'list-1'));
    });
  });
}
