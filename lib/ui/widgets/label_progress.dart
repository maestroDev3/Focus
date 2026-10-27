import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../focus_time_text.dart';

/// A label's all-time focus time and, with goals, thin lines showing how far
/// it got (#285, #337): “12h of 20h”, “1h 40 in total”, “3h of 5h this
/// week”, “… · Goal reached”.
class LabelProgress extends StatelessWidget {
  const LabelProgress({
    super.key,
    required this.total,
    this.goal,
    this.weekTotal = Duration.zero,
    this.weeklyGoal,
  });

  final Duration total;
  final Duration? goal;

  /// Focus time of this week (Monday until today).
  final Duration weekTotal;
  final Duration? weeklyGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalText = focusTimeText(l10n, total);
    final goal = this.goal;
    final weeklyGoal = this.weeklyGoal;
    final weekText = focusTimeText(l10n, weekTotal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _GoalLine(
          text: switch (goal) {
            null => l10n.labelTotal(totalText),
            _ when total >= goal => l10n.labelGoalReached(totalText),
            _ => l10n.labelGoalProgress(totalText, focusTimeText(l10n, goal)),
          },
          share: goal == null ? null : total.inSeconds / goal.inSeconds,
        ),
        if (weeklyGoal != null) ...[
          const SizedBox(height: 6),
          _GoalLine(
            text: weekTotal >= weeklyGoal
                ? l10n.labelWeekReached(weekText)
                : l10n.labelWeekProgress(
                    weekText,
                    focusTimeText(l10n, weeklyGoal),
                  ),
            share: weekTotal.inSeconds / weeklyGoal.inSeconds,
          ),
        ],
      ],
    );
  }
}

/// One line of text with, when [share] is given, a thin champagne line below.
class _GoalLine extends StatelessWidget {
  const _GoalLine({required this.text, this.share});

  final String text;
  final double? share;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.primary;
    final share = this.share;
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
        if (share != null) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: share.clamp(0.0, 1.0),
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
