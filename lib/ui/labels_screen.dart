import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/clock.dart';
import '../domain/focus_label.dart';
import '../domain/focus_session.dart';
import '../domain/label_repository.dart';
import '../domain/statistics.dart';
import '../l10n/app_localizations.dart';
import 'widgets/label_progress.dart';

/// Lets the user add, rename and delete labels and give them a goal in
/// hours; each label shows what its sessions add up to (#285).
class LabelsScreen extends StatelessWidget {
  const LabelsScreen({
    super.key,
    required this.labels,
    required this.sessions,
    this.clock = DateTime.now,
  });

  final LabelRepository labels;

  /// Finished sessions, for the all-time total of each label.
  final Stream<List<FocusSession>> sessions;

  /// Today, for the weekly goals.
  final Clock clock;

  Future<void> _edit(BuildContext context, {FocusLabel? label}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final input = await showDialog<_LabelInput>(
      context: context,
      builder: (context) => _LabelDialog(
        initialName: label?.name ?? '',
        initialGoal: label?.goal,
        initialWeeklyGoal: label?.weeklyGoal,
      ),
    );
    if (input == null) return;
    final goal = _hours(input.goal, FocusLabel.maxGoalHours);
    if (goal == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.labelGoalInvalid)));
      return;
    }
    final weeklyGoal = _hours(input.weeklyGoal, FocusLabel.maxWeeklyGoalHours);
    if (weeklyGoal == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.labelWeeklyGoalInvalid)),
      );
      return;
    }
    try {
      if (label == null) {
        final added = await labels.addLabel(input.name);
        if (goal.hours case final hours?) await labels.setGoal(added.id, hours);
        if (weeklyGoal.hours case final hours?) {
          await labels.setWeeklyGoal(added.id, hours);
        }
      } else {
        if (input.name.trim() != label.name) {
          await labels.renameLabel(label.id, input.name);
        }
        if (goal.hours != label.goal) {
          await labels.setGoal(label.id, goal.hours);
        }
        if (weeklyGoal.hours != label.weeklyGoal) {
          await labels.setWeeklyGoal(label.id, weeklyGoal.hours);
        }
      }
    } on ArgumentError {
      messenger.showSnackBar(SnackBar(content: Text(l10n.labelNameInvalid)));
    }
  }

  /// Typed whole hours: `(hours: null)` for an empty field, null if invalid.
  static ({Duration? hours})? _hours(String typed, int max) {
    final text = typed.trim();
    if (text.isEmpty) return (hours: null);
    final hours = int.tryParse(text);
    if (hours == null || hours < 1 || hours > max) return null;
    return (hours: Duration(hours: hours));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.labelsTitle)),
      body: StreamBuilder<List<FocusSession>>(
        stream: sessions,
        builder: (context, sessionSnapshot) =>
            StreamBuilder<List<FocusLabel>>(
              stream: labels.watchLabels(),
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <FocusLabel>[];
                final ids = {for (final label in items) label.id};
                final totals = labelTotals(
                  sessionSnapshot.data ?? const [],
                  labelIds: ids,
                );
                final weekTotals = labelWeekTotals(
                  sessionSnapshot.data ?? const [],
                  labelIds: ids,
                  today: clock(),
                );
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final label = items[index];
                    return ListTile(
                      title: Text(label.name),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: LabelProgress(
                          total: totals[label.id] ?? Duration.zero,
                          goal: label.goal,
                          weekTotal: weekTotals[label.id] ?? Duration.zero,
                          weeklyGoal: label.weeklyGoal,
                        ),
                      ),
                      onTap: () => _edit(context, label: label),
                      trailing: IconButton(
                        tooltip: l10n.deleteLabel(label.name),
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => labels.deleteLabel(label.id),
                      ),
                    );
                  },
                );
              },
            ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
          child: FilledButton(
            onPressed: () => _edit(context),
            child: Text(l10n.addLabel),
          ),
        ),
      ),
    );
  }
}

/// What the label dialog returns: the name and the goal as typed.
typedef _LabelInput = ({String name, String goal, String weeklyGoal});

/// Asks for a label name and an optional goal in hours; null when cancelled.
class _LabelDialog extends StatefulWidget {
  const _LabelDialog({
    required this.initialName,
    required this.initialGoal,
    required this.initialWeeklyGoal,
  });

  final String initialName;
  final Duration? initialGoal;
  final Duration? initialWeeklyGoal;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _goal = TextEditingController(
    text: widget.initialGoal?.inHours.toString() ?? '',
  );
  late final _weeklyGoal = TextEditingController(
    text: widget.initialWeeklyGoal?.inHours.toString() ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
    _weeklyGoal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.labelName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('label-name'),
            controller: _name,
            autofocus: true,
            maxLength: FocusLabel.maxLength,
            textCapitalization: TextCapitalization.sentences,
          ),
          TextField(
            key: const Key('label-goal'),
            controller: _goal,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(labelText: l10n.labelGoalHours),
          ),
          TextField(
            key: const Key('label-weekly-goal'),
            controller: _weeklyGoal,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(labelText: l10n.labelWeeklyGoalHours),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop((
                name: _name.text,
                goal: _goal.text,
                weeklyGoal: _weeklyGoal.text,
              )),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
