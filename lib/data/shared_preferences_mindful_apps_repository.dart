import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/block_list_repository.dart';
import '../domain/blocking.dart';

/// The apps that get the breathing pause (`mindful.apps.v1`). Until the user
/// edits this list it is the default list, so mindful opening starts with
/// the apps already paused.
class SharedPreferencesMindfulAppsRepository implements BlockListRepository {
  SharedPreferencesMindfulAppsRepository(
    this._preferences, {
    required this._defaultList,
  });

  static const key = 'mindful.apps.v1';
  static const _version = 1;

  final SharedPreferences _preferences;
  final BlockListRepository _defaultList;

  @override
  Future<BlockList> loadBlockList() async {
    final stored = _preferences.getString(key);
    if (stored == null) return _defaultList.loadBlockList();
    return switch (jsonDecode(stored)) {
      {'v': _version, 'packages': final List<Object?> packages}
          when packages.every((package) => package is String) =>
        BlockList(packages.cast<String>().toSet()),
      _ => throw FormatException('Unknown mindful apps: $stored'),
    };
  }

  @override
  Future<void> saveBlockList(BlockList list) async {
    await _preferences.setString(
      key,
      jsonEncode({
        'v': _version,
        'packages': list.packageNames.toList()..sort(),
      }),
    );
  }
}
