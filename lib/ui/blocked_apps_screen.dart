import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../domain/block_list_repository.dart';
import '../domain/blocking.dart';
import '../domain/focus_session.dart';
import '../domain/installed_apps_source.dart';
import '../l10n/app_localizations.dart';

/// Lets the user choose which apps are paused while focusing. In strict
/// mode (a session is active or a focus time runs) apps can only be added,
/// never removed.
class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({
    super.key,
    required this.apps,
    required this.blockList,
    required this.activeSession,
    this.inFocusTime = false,
  });

  final InstalledAppsSource apps;
  final BlockListRepository blockList;
  final FocusSession? activeSession;

  /// Whether a focus time runs right now.
  final bool inFocusTime;

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  List<InstalledApp>? _apps;
  var _blockList = const BlockList();
  var _query = '';

  /// Icons are loaded lazily and kept while the screen is open.
  final _icons = <String, Future<Uint8List?>>{};

  Future<Uint8List?> _iconOf(String packageName) =>
      _icons.putIfAbsent(packageName, () => widget.apps.iconOf(packageName));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await widget.apps.installedApps();
    final blockList = await widget.blockList.loadBlockList();
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _blockList = blockList;
    });
  }

  Future<void> _toggle(InstalledApp app, {required bool block}) async {
    final next = block
        ? _blockList.add(app.packageName)
        : _blockList.remove(app.packageName);
    setState(() => _blockList = next);
    await widget.blockList.saveBlockList(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final strict = !canRemoveFromBlockList(
      activeSession: widget.activeSession,
      inFocusTime: widget.inFocusTime,
    );
    // Without a session, a focus time is what locks the apps.
    final lockedText = widget.activeSession == null && widget.inFocusTime
        ? l10n.lockedDuringFocusTime
        : l10n.lockedDuringSession;
    final apps = _apps;
    final query = _query.trim().toLowerCase();
    final visible = [
      for (final app in apps ?? const <InstalledApp>[])
        if (query.isEmpty || app.label.toLowerCase().contains(query)) app,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedAppsTitle)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: l10n.searchApps,
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          if (strict)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                l10n.blockedAppsStrictNote,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: apps == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final app = visible[index];
                      final blocked = _blockList.contains(app.packageName);
                      final locked = strict && blocked;
                      return CheckboxListTile(
                        value: blocked,
                        title: Text(app.label),
                        subtitle: locked ? Text(lockedText) : null,
                        secondary: _AppIcon(icon: _iconOf(app.packageName)),
                        onChanged: locked
                            ? null
                            : (checked) =>
                                  _toggle(app, block: checked ?? false),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// The app's own icon, or a calm placeholder while loading or without one.
class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon});

  final Future<Uint8List?> icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox.square(
      dimension: 40,
      child: FutureBuilder<Uint8List?>(
        future: icon,
        builder: (context, snapshot) => switch (snapshot.data) {
          final bytes? => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(bytes, gaplessPlayback: true),
          ),
          null => Icon(Icons.apps, color: theme.colorScheme.onSurfaceVariant),
        },
      ),
    );
  }
}
