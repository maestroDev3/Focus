import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_focus_time_repository.dart';
import 'package:focus_timer/domain/focus_time.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late SharedPreferencesFocusTimeRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = SharedPreferencesFocusTimeRepository(preferences);
  });

  group('SharedPreferencesFocusTimeRepository', () {
    test('adds, updates and deletes focus times', () async {
      final added = await repository.addFocusTime(
        weekdays: {1, 2, 3, 4, 5},
        startMinute: 540,
        endMinute: 720,
      );
      expect(await repository.watchFocusTimes().first, [added]);

      final later = FocusTime(
        id: added.id,
        weekdays: const {1, 2, 3, 4, 5},
        startMinute: 600,
        endMinute: 720,
      );
      await repository.updateFocusTime(later);
      expect(await repository.watchFocusTimes().first, [later]);

      await repository.deleteFocusTime(added.id);
      expect(await repository.watchFocusTimes().first, isEmpty);
    });

    test('rejects overlapping focus times', () async {
      await repository.addFocusTime(
        weekdays: {1, 2, 3, 4, 5},
        startMinute: 540,
        endMinute: 720,
      );

      expect(
        () => repository.addFocusTime(
          weekdays: {3},
          startMinute: 660,
          endMinute: 780,
        ),
        throwsArgumentError,
      );
    });

    test('allows an update that only overlaps the edited focus time', () async {
      final added = await repository.addFocusTime(
        weekdays: {1},
        startMinute: 540,
        endMinute: 720,
      );

      await repository.updateFocusTime(
        FocusTime(
          id: added.id,
          weekdays: const {1},
          startMinute: 560,
          endMinute: 740,
        ),
      );

      final times = await repository.watchFocusTimes().first;
      expect(times.single.startMinute, 560);
    });

    test('persists focus times for a new instance', () async {
      final added = await repository.addFocusTime(
        weekdays: {6, 7},
        startMinute: 600,
        endMinute: 690,
      );

      expect(
        await SharedPreferencesFocusTimeRepository(
          preferences,
        ).watchFocusTimes().first,
        [added],
      );
    });

    test('persists the block list of a focus time', () async {
      final added = await repository.addFocusTime(
        weekdays: {1},
        startMinute: 480,
        endMinute: 600,
        blockListId: 'list-1',
      );

      final reloaded = await SharedPreferencesFocusTimeRepository(
        preferences,
      ).watchFocusTimes().first;

      expect(reloaded.single.blockListId, 'list-1');
      expect(reloaded, [added]);
    });

    test('loads stored focus times without block list', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.focus_times.v1':
            '{"v":1,"nextId":2,"times":[{"id":"focus-time-1",'
            '"weekdays":[1,2],"start":540,"end":720}]}',
      });
      final old = SharedPreferencesFocusTimeRepository(
        await SharedPreferences.getInstance(),
      );

      final times = await old.watchFocusTimes().first;

      expect(times.single.id, 'focus-time-1');
      expect(times.single.blockListId, isNull);
    });

    test('rejects an unknown stored version', () async {
      SharedPreferences.setMockInitialValues({'focus_times.v1': '{"v":9}'});
      final broken = SharedPreferencesFocusTimeRepository(
        await SharedPreferences.getInstance(),
      );

      expect(broken.watchFocusTimes().first, throwsFormatException);
    });
  });
}
