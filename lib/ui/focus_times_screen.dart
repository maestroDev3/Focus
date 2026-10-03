import 'package:flutter/material.dart';

import '../domain/clock.dart';
import '../domain/focus_time.dart';
import '../domain/focus_time_repository.dart';
import '../domain/named_block_list.dart';
import '../l10n/app_localizations.dart';
import 'focus_time_label.dart';

/// Lets the user plan recurring focus times.
class FocusTimesScreen extends StatelessWidget {
  const FocusTimesScreen({
    super.key,
    required this.focusTimes,
    this.namedLists,
    this.clock = DateTime.now,
  });

  final FocusTimeRepository focusTimes;

  /// Named block lists a focus time can use; without them only the default
  /// list exists and no choice is shown.
  final NamedBlockListRepository? namedLists;

  /// Decides which focus time is running and therefore locked.
  final Clock clock;

  Future<void> _edit(
    BuildContext context,
    List<NamedBlockList> lists, {
    FocusTime? time,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<_FocusTimeDraft>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FocusTimeEditor(initial: time, lists: lists),
    );
    if (result == null) return;
    try {
      // Validates weekdays and length before the overlap check.
      final candidate = FocusTime(
        id: time?.id ?? 'new',
        weekdays: result.weekdays,
        startMinute: result.startMinute,
        endMinute: result.endMinute,
        blockListId: result.blockListId,
      );
      if (time == null) {
        await focusTimes.addFocusTime(
          weekdays: candidate.weekdays,
          startMinute: candidate.startMinute,
          endMinute: candidate.endMinute,
          blockListId: candidate.blockListId,
        );
      } else {
        await focusTimes.updateFocusTime(candidate);
      }
    } on ArgumentError catch (error) {
      final overlap = '${error.message}'.contains('overlaps');
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            overlap ? l10n.focusTimeOverlaps : l10n.focusTimeInvalid,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return StreamBuilder<List<NamedBlockList>>(
      stream: namedLists?.watchLists() ?? Stream.value(const []),
      builder: (context, listSnapshot) {
        final lists = listSnapshot.data ?? const <NamedBlockList>[];
        String? listName(String? id) => [
          for (final list in lists)
            if (list.id == id) list.name,
        ].firstOrNull;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.focusTimes)),
          body: StreamBuilder<List<FocusTime>>(
            stream: focusTimes.watchFocusTimes(),
            builder: (context, snapshot) {
              final times = snapshot.data ?? const <FocusTime>[];
              if (times.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    l10n.focusTimesEmpty,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: times.length,
                itemBuilder: (context, index) {
                  final time = times[index];
                  final changeable = canChangeFocusTime(time, clock());
                  final details = [
                    ?listName(time.blockListId),
                    if (!changeable) l10n.focusTimeRunning,
                  ];
                  return ListTile(
                    leading: Icon(
                      Icons.schedule,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(focusTimeLabel(time, locale)),
                    subtitle: details.isEmpty
                        ? null
                        : Text(details.join(' · ')),
                    onTap: changeable
                        ? () => _edit(context, lists, time: time)
                        : null,
                    trailing: IconButton(
                      tooltip: l10n.deleteFocusTime,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: changeable
                          ? () => focusTimes.deleteFocusTime(time.id)
                          : null,
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
                onPressed: () => _edit(context, lists),
                child: Text(l10n.addFocusTime),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// What the editor returns.
typedef _FocusTimeDraft = ({
  Set<int> weekdays,
  int startMinute,
  int endMinute,
  String? blockListId,
});

/// Weekday chips and start/end times; defaults to Mon–Fri 09:00–12:00.
class _FocusTimeEditor extends StatefulWidget {
  const _FocusTimeEditor({required this.initial, required this.lists});

  final FocusTime? initial;

  /// Named block lists to choose from; empty → no choice shown.
  final List<NamedBlockList> lists;

  @override
  State<_FocusTimeEditor> createState() => _FocusTimeEditorState();
}

class _FocusTimeEditorState extends State<_FocusTimeEditor> {
  late final _weekdays = {...?widget.initial?.weekdays};
  late var _start = widget.initial?.startMinute ?? 9 * 60;
  late var _end = widget.initial?.endMinute ?? 12 * 60;

  /// Null = default list; a list that no longer exists counts as default.
  late String? _listId = widget.lists.any(
    (list) => list.id == widget.initial?.blockListId,
  )
      ? widget.initial?.blockListId
      : null;

  @override
  void initState() {
    super.initState();
    if (widget.initial == null) _weekdays.addAll({1, 2, 3, 4, 5});
  }

  Future<void> _pick({required bool start}) async {
    final minute = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (picked == null || !mounted) return;
    setState(() {
      final value = picked.hour * 60 + picked.minute;
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    label: Text(weekdayName(day, locale)),
                    selected: _weekdays.contains(day),
                    onSelected: (selected) => setState(() {
                      if (selected) {
                        _weekdays.add(day);
                      } else {
                        _weekdays.remove(day);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text(l10n.focusTimeStart),
              trailing: Text(minuteOfDayText(_start, locale)),
              onTap: () => _pick(start: true),
            ),
            ListTile(
              title: Text(l10n.focusTimeEnd),
              trailing: Text(minuteOfDayText(_end, locale)),
              onTap: () => _pick(start: false),
            ),
            if (widget.lists.isNotEmpty)
              ListTile(
                title: Text(l10n.focusTimeBlockList),
                trailing: DropdownButton<String?>(
                  value: _listId,
                  underline: const SizedBox.shrink(),
                  onChanged: (id) => setState(() => _listId = id),
                  items: [
                    DropdownMenuItem(child: Text(l10n.defaultBlockList)),
                    for (final list in widget.lists)
                      DropdownMenuItem(value: list.id, child: Text(list.name)),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((
                weekdays: Set.of(_weekdays),
                startMinute: _start,
                endMinute: _end,
                blockListId: _listId,
              )),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
