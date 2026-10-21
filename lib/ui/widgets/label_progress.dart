import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../focus_time_text.dart';

/// A label's all-time focus time, and with a goal a thin line showing how
/// far it got (#285): “12h of 20h”, “1h 40 in total”, “… · Goal reached”.
class LabelProgress extends StatelessWidget {
  const LabelProgress({super.key, required this.total, this.goal});

  final Duration total;
  final Duration? goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final totalText = focusTimeText(l10n, total);
    final goal = this.goal;
    final text = switch (goal) {
      null => l10n.labelTotal(totalText),
      _ when total >= goal => l10n.labelGoalReached(totalText),
      _ => l10n.labelGoalProgress(totalText, focusTimeText(l10n, goal)),
    };
    final gold = theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (goal != null) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: (total.inSeconds / goal.inSeconds).clamp(0.0, 1.0),
            minHeight: 2,
            color: gold,
            backgroundColor: gold.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(1),
          ),
        ],
      ],
    );
  }
}
