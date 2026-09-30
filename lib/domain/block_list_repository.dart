import 'blocking.dart';

/// Stores the apps the user wants to pause while focusing.
abstract interface class BlockListRepository {
  /// The saved block list, or an empty one.
  Future<BlockList> loadBlockList();

  Future<void> saveBlockList(BlockList list);
}
