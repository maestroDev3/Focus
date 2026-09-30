import '../l10n/app_localizations.dart';

/// Formats a focus time calmly: “45 min”, “3h” or “1h 40”.
String focusTimeText(AppLocalizations l10n, Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours == 0) return l10n.durationMinutes(minutes);
  if (minutes == 0) return l10n.durationHours(hours);
  return l10n.durationHoursMinutes(hours, minutes.toString().padLeft(2, '0'));
}
