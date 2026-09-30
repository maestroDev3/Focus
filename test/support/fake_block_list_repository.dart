import 'package:focus_timer/domain/block_list_repository.dart';
import 'package:focus_timer/domain/blocking.dart';

/// In-memory [BlockListRepository] for tests.
class FakeBlockListRepository implements BlockListRepository {
  FakeBlockListRepository([this.blockList = const BlockList()]);

  BlockList blockList;

  @override
  Future<BlockList> loadBlockList() async => blockList;

  @override
  Future<void> saveBlockList(BlockList list) async => blockList = list;
}
