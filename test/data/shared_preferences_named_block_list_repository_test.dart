import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_named_block_list_repository.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/named_block_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late SharedPreferencesNamedBlockListRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = SharedPreferencesNamedBlockListRepository(preferences);
  });

  List<String> names(List<NamedBlockList> lists) => [
    for (final list in lists) list.name,
  ];

  group('SharedPreferencesNamedBlockListRepository', () {
    test('replaces all lists and keeps their ids', () async {
      await repository.addList('Old');
      final restored = [
        NamedBlockList(
          id: 'list-5',
          name: 'Morning',
          apps: const BlockList({'com.instagram.android'}),
        ),
      ];

      final emitted = repository.watchLists().skip(1).first;
      await repository.replaceAll(restored);

      expect(await emitted, restored);
      expect(await repository.watchLists().first, restored);
      expect((await repository.addList('Evening')).id, 'list-6');
    });

    test('emits added lists in insertion order', () async {
      final emitted = <List<String>>[];
      final subscription = repository.watchLists().listen(
        (lists) => emitted.add(names(lists)),
      );
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      await repository.addList('Morning');
      await repository.addList('Evening');
      await Future<void>.delayed(Duration.zero);

      expect(emitted.first, isEmpty);
      expect(emitted.last, ['Morning', 'Evening']);
    });

    test('rejects duplicate names ignoring case', () async {
      final morning = await repository.addList('Morning');
      await repository.addList('Evening');

      expect(() => repository.addList('morning'), throwsArgumentError);
      expect(
        () => repository.renameList(morning.id, 'EVENING'),
        throwsArgumentError,
      );
    });

    test('renames and deletes lists', () async {
      final morning = await repository.addList('Morning');
      final evening = await repository.addList('Evening');

      await repository.renameList(morning.id, 'Deep work');
      await repository.deleteList(evening.id);

      expect(names(await repository.watchLists().first), ['Deep work']);
    });

    test('stores the apps of one list', () async {
      final morning = await repository.addList('Morning');
      await repository.addList('Evening');

      await repository.saveApps(
        morning.id,
        const BlockList().add('com.instagram.android'),
      );

      final lists = await repository.watchLists().first;
      expect(lists.first.apps, const BlockList().add('com.instagram.android'));
      expect(lists.last.apps, const BlockList());
    });

    test('loads stored lists again after a restart', () async {
      final morning = await repository.addList('Morning');
      await repository.saveApps(
        morning.id,
        const BlockList().add('com.google.android.youtube'),
      );

      final reloaded = SharedPreferencesNamedBlockListRepository(preferences);
      final lists = await reloaded.watchLists().first;

      expect(lists.single.id, morning.id);
      expect(lists.single.name, 'Morning');
      expect(
        lists.single.apps,
        const BlockList().add('com.google.android.youtube'),
      );
    });

    test('never reuses the id of a deleted list', () async {
      final first = await repository.addList('Morning');
      await repository.deleteList(first.id);

      final second = await repository.addList('Evening');

      expect(second.id, isNot(first.id));
    });

    test('throws on unknown stored data', () async {
      SharedPreferences.setMockInitialValues({
        'flutter.${SharedPreferencesNamedBlockListRepository.key}': '{"v":99}',
      });
      final broken = SharedPreferencesNamedBlockListRepository(
        await SharedPreferences.getInstance(),
      );

      expect(broken.watchLists().first, throwsFormatException);
    });
  });
}
