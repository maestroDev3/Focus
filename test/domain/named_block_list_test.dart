import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/named_block_list.dart';

import '../support/fake_named_block_list_repository.dart';

void main() {
  group('NamedBlockList', () {
    test('trims the name', () {
      expect(NamedBlockList(id: 'list-1', name: '  Morning ').name, 'Morning');
    });

    test('rejects empty and too long names', () {
      expect(() => NamedBlockList(id: 'list-1', name: '   '), throwsArgumentError);
      expect(
        () => NamedBlockList(id: 'list-1', name: 'x' * 31),
        throwsArgumentError,
      );
    });
  });

  group('NamedBlockListApps', () {
    test('loads and saves the apps of its list', () async {
      final repository = FakeNamedBlockListRepository();
      final morning = await repository.addList('Morning');
      final evening = await repository.addList('Evening');
      final apps = NamedBlockListApps(repository: repository, listId: morning.id);

      await apps.saveBlockList(const BlockList().add('org.telegram.messenger'));

      expect(
        await apps.loadBlockList(),
        const BlockList().add('org.telegram.messenger'),
      );
      final lists = await repository.watchLists().first;
      expect(
        lists.firstWhere((list) => list.id == evening.id).apps,
        const BlockList(),
      );
    });
  });
}
