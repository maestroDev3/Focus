import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/focus_label.dart';
import '../domain/focus_session.dart';
import '../domain/label_repository.dart';
import '../domain/statistics.dart';
import '../l10n/app_localizations.dart';
import 'widgets/label_progress.dart';

/// Lets the user add, rename and delete labels and give them a goal in
/// hours; each label shows what its sessions add up to (#285).
class LabelsScreen extends StatelessWidget {
  const LabelsScreen({super.key, required this.labels, required this.sessions});

  final LabelRepository labels;

  /// Finished sessions, for the all-time total of each label.
  final Stream<List<FocusSession>> sessions;

  Future<void> _edit(BuildContext context, {FocusLabel? label}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final input = await showDialog<_LabelInput>(
      context: context,
      builder: (context) => _LabelDialog(
        initialName: label?.name ?? '',
        initialGoal: label?.goal,
      ),
    );
    if (input == null) return;
    final Duration? goal;
    switch (input.goal.trim()) {
      case '':
        goal = null;
      case final typed:
        final hours = int.tryParse(typed);
        if (hours == null || hours < 1 || hours > FocusLabel.maxGoalHours) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.labelGoalInvalid)),
          );
          return;
        }
        goal = Duration(hours: hours);
    }
    try {
      if (label == null) {
        final added = await labels.addLabel(input.name);
        if (goal != null) await labels.setGoal(added.id, goal);
      } else {
        if (input.name.trim() != label.name) {
          await labels.renameLabel(label.id, input.name);
        }
        if (goal != label.goal) await labels.setGoal(label.id, goal);
      }
    } on ArgumentError {
      messenger.showSnackBar(SnackBar(content: Text(l10n.labelNameInvalid)));
    }
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
                final totals = labelTotals(
                  sessionSnapshot.data ?? const [],
                  labelIds: {for (final label in items) label.id},
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
typedef _LabelInput = ({String name, String goal});

/// Asks for a label name and an optional goal in hours; null when cancelled.
class _LabelDialog extends StatefulWidget {
  const _LabelDialog({required this.initialName, required this.initialGoal});

  final String initialName;
  final Duration? initialGoal;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final _name = TextEditingController(text: widget.initialName);
  late final _goal = TextEditingController(
    text: widget.initialGoal?.inHours.toString() ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _goal.dispose();
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop((name: _name.text, goal: _goal.text)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
