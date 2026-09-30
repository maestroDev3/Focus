import 'package:focus_timer/domain/blocking.dart';

/// Records every written [BlockingState] for tests.
class FakeBlockingStateWriter implements BlockingStateWriter {
  final written = <BlockingState>[];

  BlockingState? get last => written.isEmpty ? null : written.last;

  @override
  Future<void> write(BlockingState state) async => written.add(state);
}
