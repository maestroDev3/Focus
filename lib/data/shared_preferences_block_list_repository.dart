import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/block_list_repository.dart';
import '../domain/blocking.dart';

/// Stores the block list as versioned JSON in shared preferences.
class SharedPreferencesBlockListRepository implements BlockListRepository {
  SharedPreferencesBlockListRepository(this._preferences);

  static const key = 'blocking.list.v1';
  static const _version = 1;

  final SharedPreferences _preferences;

  @override
  Future<BlockList> loadBlockList() async {
    final stored = _preferences.getString(key);
    if (stored == null) return const BlockList();
    return switch (jsonDecode(stored)) {
      {'v': _version, 'packages': final List<Object?> packages}
          when packages.every((package) => package is String) =>
        BlockList(packages.cast<String>().toSet()),
      _ => throw FormatException('Unknown block list: $stored'),
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
