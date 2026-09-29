import 'pomodoro.dart';

/// A break between focus sessions, derived from timestamps like sessions.
class BreakSession {
  const BreakSession({
    required this.start,
    required this.kind,
    required this.duration,
  });

  final DateTime start;
  final BreakKind kind;
  final Duration duration;

  /// Break time still left at [now]; never negative.
  Duration remaining(DateTime now) {
    final left = duration - now.difference(start);
    return left.isNegative ? Duration.zero : left;
  }

  bool isOver(DateTime now) => remaining(now) == Duration.zero;
}
