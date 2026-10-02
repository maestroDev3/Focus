/// What the ongoing notification shows during a focus session.
sealed class CountdownNotice {
  const CountdownNotice({this.labelName});

  /// Name of the session's label, if it has one.
  final String? labelName;
}

/// The session runs and ends at [end]; the platform counts down by itself.
final class CountdownRunning extends CountdownNotice {
  const CountdownRunning({required this.end, super.labelName});

  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is CountdownRunning &&
      other.end == end &&
      other.labelName == labelName;

  @override
  int get hashCode => Object.hash(end, labelName);

  @override
  String toString() => 'CountdownRunning(end: $end, labelName: $labelName)';
}

/// The session is paused with [remaining] time left.
final class CountdownPaused extends CountdownNotice {
  const CountdownPaused({required this.remaining, super.labelName});

  final Duration remaining;

  @override
  bool operator ==(Object other) =>
      other is CountdownPaused &&
      other.remaining == remaining &&
      other.labelName == labelName;

  @override
  int get hashCode => Object.hash(remaining, labelName);

  @override
  String toString() =>
      'CountdownPaused(remaining: $remaining, labelName: $labelName)';
}

/// Shows the remaining focus time outside the app, e.g. as an ongoing
/// notification that keeps counting while Focus is closed.
abstract interface class SessionCountdown {
  /// Shows [notice], replacing what was shown before.
  Future<void> show(CountdownNotice notice);

  /// Removes the countdown, e.g. when the session ended.
  Future<void> hide();
}
