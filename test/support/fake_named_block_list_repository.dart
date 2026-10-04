import 'dart:async';

import 'package:focus_timer/domain/blocking.dart';
import 'package:focus_timer/domain/named_block_list.dart';

/// In-memory [NamedBlockListRepository] for tests, with the same name rules.
class FakeNamedBlockListRepository implements NamedBlockListRepository {
  FakeNamedBlockListRepository([List<NamedBlockList> lists = const []])
    : lists = List.of(lists);

  final List<NamedBlockList> lists;
  final _changes = StreamController<List<NamedBlockList>>.broadcast();
  var _nextId = 100;

  @override
  Stream<List<NamedBlockList>> watchLists() async* {
    yield List.of(lists);
    yield* _changes.stream;
  }

  @override
  Future<NamedBlockList> addList(String name) async {
    checkUniqueBlockListName(lists, name);
    final list = NamedBlockList(id: 'list-${_nextId++}', name: name);
    lists.add(list);
    _changes.add(List.of(lists));
    return list;
  }

  @override
  Future<void> renameList(String id, String name) async {
    checkUniqueBlockListName(lists, name, exceptId: id);
    _replace(id, (list) => list.copyWith(name: name));
  }

  @override
  Future<void> deleteList(String id) async {
    lists.removeWhere((list) => list.id == id);
    _changes.add(List.of(lists));
  }

  @override
  Future<void> saveApps(String id, BlockList apps) async =>
      _replace(id, (list) => list.copyWith(apps: apps));

  @override
  Future<void> replaceAll(List<NamedBlockList> lists) async {
    this.lists
      ..clear()
      ..addAll(lists);
    _changes.add(List.of(this.lists));
  }

  void _replace(String id, NamedBlockList Function(NamedBlockList) change) {
    final index = lists.indexWhere((list) => list.id == id);
    if (index < 0) throw StateError('Unknown block list $id');
    lists[index] = change(lists[index]);
    _changes.add(List.of(lists));
  }
}
