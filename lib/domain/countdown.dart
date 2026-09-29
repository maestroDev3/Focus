/// Formats a remaining time as `mm:ss` (or `h:mm:ss` from one hour on).
/// Partial seconds round up, so `00:00` only shows when time is really up.
String formatCountdown(Duration remaining) {
  final totalSeconds =
      (remaining.inMicroseconds / Duration.microsecondsPerSecond).ceil();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String twoDigits(int value) => value.toString().padLeft(2, '0');

  return hours > 0
      ? '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}'
      : '${twoDigits(minutes)}:${twoDigits(seconds)}';
}
