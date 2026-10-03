import 'package:flutter/material.dart';

import '../domain/block_list_repository.dart';
import '../domain/focus_session.dart';
import '../domain/installed_apps_source.dart';
import '../domain/named_block_list.dart';
import '../l10n/app_localizations.dart';
import 'blocked_apps_screen.dart';

/// Overview of the default block list and the user's named lists; each list
/// opens the app picker for exactly that list.
class BlockListsScreen extends StatefulWidget {
  const BlockListsScreen({
    super.key,
    required this.apps,
    required this.defaultList,
    required this.namedLists,
    required this.activeSession,
    this.inFocusTime = false,
  });

  final InstalledAppsSource apps;
  final BlockListRepository defaultList;
  final NamedBlockListRepository namedLists;

  /// Make the default list strict while a session or focus time runs.
  final FocusSession? activeSession;
  final bool inFocusTime;

  @override
  State<BlockListsScreen> createState() => _BlockListsScreenState();
}

class _BlockListsScreenState extends State<BlockListsScreen> {
  var _defaultCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDefaultCount();
  }

  Future<void> _loadDefaultCount() async {
    final list = await widget.defaultList.loadBlockList();
    if (!mounted) return;
    setState(() => _defaultCount = list.length);
  }

  Future<void> _openDefault() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BlockedAppsScreen(
          title: AppLocalizations.of(context).defaultBlockList,
          apps: widget.apps,
          blockList: widget.defaultList,
          activeSession: widget.activeSession,
          inFocusTime: widget.inFocusTime,
        ),
      ),
    );
    await _loadDefaultCount();
  }

  Future<void> _openNamed(NamedBlockList list) async {
    // Named lists aren't used by sessions or focus times yet (#144), so
    // they are never strict here.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BlockedAppsScreen(
          title: list.name,
          apps: widget.apps,
          blockList: NamedBlockListApps(
            repository: widget.namedLists,
            listId: list.id,
          ),
          activeSession: null,
        ),
      ),
    );
  }

  Future<void> _editName({NamedBlockList? list}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => _ListNameDialog(initialName: list?.name ?? ''),
    );
    if (name == null) return;
    try {
      if (list == null) {
        await widget.namedLists.addList(name);
      } else {
        await widget.namedLists.renameList(list.id, name);
      }
    } on ArgumentError {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.blockListNameInvalid)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockListsTitle)),
      body: StreamBuilder<List<NamedBlockList>>(
        stream: widget.namedLists.watchLists(),
        builder: (context, snapshot) {
          final lists = snapshot.data ?? const <NamedBlockList>[];
          return ListView.builder(
            itemCount: lists.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  leading: const Icon(Icons.block),
                  title: Text(l10n.defaultBlockList),
                  subtitle: Text(l10n.defaultBlockListSummary(_defaultCount)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _openDefault,
                );
              }
              final list = lists[index - 1];
              return ListTile(
                key: ValueKey('block-list-${list.id}'),
                leading: const Icon(Icons.list_alt),
                title: Text(list.name),
                subtitle: Text(l10n.blockListAppCount(list.apps.length)),
                onTap: () => _openNamed(list),
                trailing: PopupMenuButton<_ListAction>(
                  tooltip: l10n.blockListOptions(list.name),
                  onSelected: (action) => switch (action) {
                    _ListAction.rename => _editName(list: list),
                    _ListAction.delete => widget.namedLists.deleteList(list.id),
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _ListAction.rename,
                      child: Text(l10n.renameBlockList),
                    ),
                    PopupMenuItem(
                      value: _ListAction.delete,
                      child: Text(l10n.deleteBlockList),
                    ),
                  ],
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
            onPressed: _editName,
            child: Text(l10n.newBlockList),
          ),
        ),
      ),
    );
  }
}

enum _ListAction { rename, delete }

/// Asks for a list name; returns it, or null when cancelled.
class _ListNameDialog extends StatefulWidget {
  const _ListNameDialog({required this.initialName});

  final String initialName;

  @override
  State<_ListNameDialog> createState() => _ListNameDialogState();
}

class _ListNameDialogState extends State<_ListNameDialog> {
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
      title: Text(l10n.blockListName),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: NamedBlockList.maxNameLength,
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
