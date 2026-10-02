import 'package:focus_timer/domain/session_countdown.dart';

/// Records the notice shown last; null when hidden.
class FakeSessionCountdown implements SessionCountdown {
  CountdownNotice? shown;

  @override
  Future<void> show(CountdownNotice notice) async => shown = notice;

  @override
  Future<void> hide() async => shown = null;
}
