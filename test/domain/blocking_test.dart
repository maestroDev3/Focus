import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/focus_session.dart';

void main() {
  const youtube = 'com.google.android.youtube';
  const instagram = 'com.instagram.android';

  group('BlockList', () {
    test('adds and removes package names as new lists', () {
      const empty = BlockList();
      final withYoutube = empty.add(youtube);
      final withBoth = withYoutube.add(instagram);

      expect(empty.contains(youtube), isFalse);
      expect(withYoutube.contains(youtube), isTrue);
      expect(withBoth.length, 2);
      expect(withBoth.remove(youtube), BlockList(const {instagram}));
    });

    test('ignores duplicates', () {
      expect(const BlockList().add(youtube).add(youtube).length, 1);
    });

    test('never blocks Focus itself', () {
      expect(
        () => const BlockList().add('de.maestrodev.focus_timer'),
        throwsArgumentError,
      );
    });
  });

  group('canRemoveFromBlockList', () {
    final start = DateTime(2026, 9, 30, 10);
    FocusSession running() =>
        FocusSession(start: start, planned: const Duration(minutes: 25));

    test('is false while a session runs or is paused', () {
      expect(canRemoveFromBlockList(activeSession: running()), isFalse);
      expect(
        canRemoveFromBlockList(
          activeSession: running().pause(start.add(const Duration(minutes: 1))),
        ),
        isFalse,
      );
    });

    test('is false during a focus time, also without a session', () {
      expect(
        canRemoveFromBlockList(activeSession: null, inFocusTime: true),
        isFalse,
      );
    });

    test('is true without a session or after it ended', () {
      expect(canRemoveFromBlockList(activeSession: null), isTrue);
      expect(
        canRemoveFromBlockList(
          activeSession: running().cancel(start.add(const Duration(minutes: 1))),
        ),
        isTrue,
      );
    });
  });
}
