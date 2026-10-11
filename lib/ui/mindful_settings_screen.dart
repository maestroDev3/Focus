import 'package:flutter/material.dart';

import '../domain/block_list_repository.dart';
import '../domain/blocking.dart';
import '../domain/installed_apps_source.dart';
import '../domain/settings_repository.dart';
import '../l10n/app_localizations.dart';
import 'blocked_apps_screen.dart';

/// Settings of mindful opening: how long the breathing pause lasts and which
/// apps get it.
class MindfulSettingsScreen extends StatefulWidget {
  const MindfulSettingsScreen({
    super.key,
    required this.settings,
    required this.mindfulApps,
    required this.installedApps,
    this.onChanged,
  });

  final SettingsRepository settings;

  /// The apps that get the breathing pause.
  final BlockListRepository mindfulApps;
  final InstalledAppsSource installedApps;

  /// Called after the pause or the apps changed, so the blocker learns it.
  final VoidCallback? onChanged;

  @override
  State<MindfulSettingsScreen> createState() => _MindfulSettingsScreenState();
}

class _MindfulSettingsScreenState extends State<MindfulSettingsScreen> {
  Duration? _pause;
  var _appCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final pause = await widget.settings.loadMindfulPause();
    final apps = await widget.mindfulApps.loadBlockList();
    if (!mounted) return;
    setState(() {
      _pause = pause;
      _appCount = apps.length;
    });
  }

  Future<void> _choosePause(Duration pause) async {
    setState(() => _pause = pause);
    await widget.settings.saveMindfulPause(pause);
    widget.onChanged?.call();
  }

  Future<void> _editApps() async {
    final title = AppLocalizations.of(context).mindfulApps;
    final before = await widget.mindfulApps.loadBlockList();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => BlockedAppsScreen(
          title: title,
          apps: widget.installedApps,
          blockList: widget.mindfulApps,
          // Not a block: apps can always be removed again.
          activeSession: null,
        ),
      ),
    );
    final after = await widget.mindfulApps.loadBlockList();
    await _load();
    if (after != before) widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final pause = _pause;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mindfulOpening)),
      body: pause == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
                  child: Text(
                    l10n.mindfulOpeningDetails,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ListTile(
                  title: Text(l10n.mindfulPauseLength),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SegmentedButton<Duration>(
                      segments: [
                        for (final option in mindfulPauseOptions)
                          ButtonSegment(
                            value: option,
                            label: Text(
                              l10n.mindfulPauseSeconds(option.inSeconds),
                            ),
                          ),
                      ],
                      selected: {pause},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          _choosePause(selection.first),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.apps),
                  title: Text(l10n.mindfulApps),
                  subtitle: Text(l10n.blockListAppCount(_appCount)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _editApps,
                ),
              ],
            ),
    );
  }
}
