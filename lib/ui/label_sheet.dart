import 'package:flutter/material.dart';

import '../domain/focus_label.dart';
import '../l10n/app_localizations.dart';

/// Bottom sheet to pick the label for the next session.
class LabelSheet extends StatelessWidget {
  const LabelSheet({
    super.key,
    required this.labels,
    required this.selectedId,
    required this.onSelect,
    required this.onManage,
  });

  final List<FocusLabel> labels;
  final String? selectedId;
  final ValueChanged<String?> onSelect;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    Widget? check(bool selected) =>
        selected ? Icon(Icons.check, color: theme.colorScheme.primary) : null;

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(l10n.noLabel),
            trailing: check(selectedId == null),
            onTap: () => onSelect(null),
          ),
          for (final label in labels)
            ListTile(
              title: Text(label.name),
              trailing: check(label.id == selectedId),
              onTap: () => onSelect(label.id),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.manageLabels),
            onTap: onManage,
          ),
        ],
      ),
    );
  }
}
