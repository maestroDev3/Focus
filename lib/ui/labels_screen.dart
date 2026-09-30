import 'package:flutter/material.dart';

import '../domain/focus_label.dart';
import '../domain/label_repository.dart';
import '../l10n/app_localizations.dart';

/// Lets the user add, rename and delete labels.
class LabelsScreen extends StatelessWidget {
  const LabelsScreen({super.key, required this.labels});

  final LabelRepository labels;

  Future<void> _edit(BuildContext context, {FocusLabel? label}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _LabelNameDialog(initialName: label?.name ?? ''),
    );
    if (name == null) return;
    try {
      if (label == null) {
        await labels.addLabel(name);
      } else {
        await labels.renameLabel(label.id, name);
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
      body: StreamBuilder<List<FocusLabel>>(
        stream: labels.watchLabels(),
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <FocusLabel>[];
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final label = items[index];
              return ListTile(
                title: Text(label.name),
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

/// Asks for a label name; returns it, or null when cancelled.
class _LabelNameDialog extends StatefulWidget {
  const _LabelNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_LabelNameDialog> createState() => _LabelNameDialogState();
}

class _LabelNameDialogState extends State<_LabelNameDialog> {
  late final _controller = TextEditingController(text: widget.initialName);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.labelName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: FocusLabel.maxLength,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
