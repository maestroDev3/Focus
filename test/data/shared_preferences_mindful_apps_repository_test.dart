import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_mindful_apps_repository.dart';
import 'package:focus_timer/domain/blocking.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_block_list_repository.dart';

void main() {
  const telegram = 'org.telegram.messenger';
  const instagram = 'com.instagram.android';

  group('SharedPreferencesMindfulAppsRepository', () {
    test('starts with the default list', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SharedPreferencesMindfulAppsRepository(
        await SharedPreferences.getInstance(),
        defaultList: FakeBlockListRepository(
          const BlockList({telegram, instagram}),
        ),
      );

      expect(
        await repository.loadBlockList(),
        const BlockList({telegram, instagram}),
      );
    });

    test('keeps its own list once saved', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final defaultList = FakeBlockListRepository(
        const BlockList({telegram, instagram}),
      );
      await SharedPreferencesMindfulAppsRepository(
        preferences,
        defaultList: defaultList,
      ).saveBlockList(const BlockList({instagram}));
      defaultList.blockList = const BlockList({telegram});

      expect(
        await SharedPreferencesMindfulAppsRepository(
          preferences,
          defaultList: defaultList,
        ).loadBlockList(),
        const BlockList({instagram}),
      );
    });
  });
}
