import 'package:focus_timer/domain/home_widget.dart';

/// Records published snapshots and hands out one pending widget start.
class FakeHomeWidgetBridge implements HomeWidgetBridge {
  final published = <WidgetSnapshot>[];
  ExternalStart? pending;

  @override
  Future<void> publish(WidgetSnapshot snapshot) async =>
      published.add(snapshot);

  @override
  Future<ExternalStart?> takePendingStart() async {
    final start = pending;
    pending = null;
    return start;
  }
}
