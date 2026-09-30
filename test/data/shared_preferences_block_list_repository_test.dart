import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_block_list_repository.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesBlockListRepository', () {
    test('returns an empty list by default', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SharedPreferencesBlockListRepository(
        await SharedPreferences.getInstance(),
      );

      expect(await repository.loadBlockList(), const BlockList());
    });

    test('persists a saved list for a new instance', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final list = const BlockList()
          .add('com.google.android.youtube')
          .add('org.telegram.messenger');

      await SharedPreferencesBlockListRepository(
        preferences,
      ).saveBlockList(list);

      expect(
        await SharedPreferencesBlockListRepository(
          preferences,
        ).loadBlockList(),
        list,
      );
    });

    test('rejects an unknown stored version', () async {
      SharedPreferences.setMockInitialValues({
        'blocking.list.v1': '{"v":7,"packages":[]}',
      });
      final repository = SharedPreferencesBlockListRepository(
        await SharedPreferences.getInstance(),
      );

      expect(repository.loadBlockList(), throwsFormatException);
    });
  });
}
