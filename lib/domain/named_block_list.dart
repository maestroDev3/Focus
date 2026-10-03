import 'block_list_repository.dart';
import 'blocking.dart';

/// A block list with a name (e.g. “Morning”), next to the default list.
/// Focus times and labels can use it instead of / in addition to the
/// default list.
class NamedBlockList {
  NamedBlockList({
    required this.id,
    required String name,
    this.apps = const BlockList(),
  }) : name = name.trim() {
    if (this.name.isEmpty || this.name.length > maxNameLength) {
      throw ArgumentError.value(
        name,
        'name',
        'must be 1–$maxNameLength characters',
      );
    }
  }

  static const maxNameLength = 30;

  final String id;
  final String name;
  final BlockList apps;

  NamedBlockList copyWith({String? name, BlockList? apps}) =>
      NamedBlockList(id: id, name: name ?? this.name, apps: apps ?? this.apps);

  @override
  bool operator ==(Object other) =>
      other is NamedBlockList &&
      other.id == id &&
      other.name == name &&
      other.apps == apps;

  @override
  int get hashCode => Object.hash(id, name, apps);
}

/// Throws [ArgumentError] if another list in [lists] already has [name]
/// (ignoring case and surrounding spaces).
void checkUniqueBlockListName(
  List<NamedBlockList> lists,
  String name, {
  String? exceptId,
}) {
  final wanted = name.trim().toLowerCase();
  final taken = lists.any(
    (list) => list.id != exceptId && list.name.toLowerCase() == wanted,
  );
  if (taken) throw ArgumentError.value(name, 'name', 'is already used');
}

/// Stores the user's named block lists. Names are unique ignoring case.
abstract interface class NamedBlockListRepository {
  /// Emits all lists in insertion order now and after every change.
  Stream<List<NamedBlockList>> watchLists();

  /// Adds an empty list; throws [ArgumentError] for invalid or duplicate names.
  Future<NamedBlockList> addList(String name);

  Future<void> renameList(String id, String name);

  Future<void> deleteList(String id);

  /// Replaces the apps of the list with [id].
  Future<void> saveApps(String id, BlockList apps);
}

/// One named list seen as a [BlockListRepository], so the app picker can
/// edit it like the default list.
class NamedBlockListApps implements BlockListRepository {
  const NamedBlockListApps({required this.repository, required this.listId});

  final NamedBlockListRepository repository;
  final String listId;

  @override
  Future<BlockList> loadBlockList() async {
    final lists = await repository.watchLists().first;
    return [
          for (final list in lists)
            if (list.id == listId) list.apps,
        ].firstOrNull ??
        const BlockList();
  }

  @override
  Future<void> saveBlockList(BlockList list) =>
      repository.saveApps(listId, list);
}
