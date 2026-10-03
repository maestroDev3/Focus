import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/blocking.dart';
import '../domain/named_block_list.dart';

/// Stores named block lists as versioned JSON (`blocking.lists.v1`) with a
/// running id counter, so ids are never reused. The default list keeps its
/// own key (`blocking.list.v1`).
class SharedPreferencesNamedBlockListRepository
    implements NamedBlockListRepository {
  SharedPreferencesNamedBlockListRepository(this._preferences);

  static const key = 'blocking.lists.v1';
  static const _version = 1;

  final SharedPreferences _preferences;
  final _changes = StreamController<List<NamedBlockList>>.broadcast();

  @override
  Stream<List<NamedBlockList>> watchLists() async* {
    yield _load().lists;
    yield* _changes.stream;
  }

  @override
  Future<NamedBlockList> addList(String name) async {
    final (:lists, :nextId) = _load();
    checkUniqueBlockListName(lists, name);
    final list = NamedBlockList(id: 'list-$nextId', name: name);
    await _save([...lists, list], nextId + 1);
    return list;
  }

  @override
  Future<void> renameList(String id, String name) async {
    final (:lists, :nextId) = _load();
    checkUniqueBlockListName(lists, name, exceptId: id);
    await _save([
      for (final list in lists) list.id == id ? list.copyWith(name: name) : list,
    ], nextId);
  }

  @override
  Future<void> deleteList(String id) async {
    final (:lists, :nextId) = _load();
    await _save([
      for (final list in lists)
        if (list.id != id) list,
    ], nextId);
  }

  @override
  Future<void> saveApps(String id, BlockList apps) async {
    final (:lists, :nextId) = _load();
    await _save([
      for (final list in lists) list.id == id ? list.copyWith(apps: apps) : list,
    ], nextId);
  }

  ({List<NamedBlockList> lists, int nextId}) _load() {
    final stored = _preferences.getString(key);
    if (stored == null) return (lists: const [], nextId: 1);
    return switch (jsonDecode(stored)) {
      {
        'v': _version,
        'nextId': final int nextId,
        'lists': final List<Object?> items,
      } =>
        (
          lists: [
            for (final item in items)
              switch (item) {
                {
                  'id': final String id,
                  'name': final String name,
                  'packages': final List<Object?> packages,
                } when packages.every((package) => package is String) =>
                  NamedBlockList(
                    id: id,
                    name: name,
                    apps: BlockList(packages.cast<String>().toSet()),
                  ),
                _ => throw FormatException('Malformed block list: $item'),
              },
          ],
          nextId: nextId,
        ),
      _ => throw FormatException('Unknown block lists data: $stored'),
    };
  }

  Future<void> _save(List<NamedBlockList> lists, int nextId) async {
    await _preferences.setString(
      key,
      jsonEncode({
        'v': _version,
        'nextId': nextId,
        'lists': [
          for (final list in lists)
            {
              'id': list.id,
              'name': list.name,
              'packages': list.apps.packageNames.toList()..sort(),
            },
        ],
      }),
    );
    _changes.add(lists);
  }
}
