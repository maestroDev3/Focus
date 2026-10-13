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
      final candidate = FocusTime.withRanges(
        id: time?.id ?? 'new',
        ranges: [
          for (final range in result.ranges)
            FocusTimeRange(
              weekdays: range.weekdays,
              startMinute: range.startMinute,
              endMinute: range.endMinute,
            ),
        ],
        blockListId: result.blockListId,
      );
      if (time == null) {
        await focusTimes.addFocusTime(
          ranges: candidate.ranges,
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

/// One range as edited; validated only when saving.
typedef _RangeDraft = ({Set<int> weekdays, int startMinute, int endMinute});

/// What the editor returns.
typedef _FocusTimeDraft = ({List<_RangeDraft> ranges, String? blockListId});

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
  /// Defaults to one range Mon–Fri 09:00–12:00.
  late final _ranges = <_RangeDraft>[
    for (final range in widget.initial?.ranges ?? const <FocusTimeRange>[])
      (
        weekdays: {...range.weekdays},
        startMinute: range.startMinute,
        endMinute: range.endMinute,
      ),
    if (widget.initial == null)
      (weekdays: {1, 2, 3, 4, 5}, startMinute: 9 * 60, endMinute: 12 * 60),
  ];

  /// Null = default list; a list that no longer exists counts as default.
  late String? _listId = widget.lists.any(
    (list) => list.id == widget.initial?.blockListId,
  )
      ? widget.initial?.blockListId
      : null;

  /// A new range starts with the hours of the last one and no days.
  void _addRange() => setState(() {
    final last = _ranges.last;
    _ranges.add((
      weekdays: <int>{},
      startMinute: last.startMinute,
      endMinute: last.endMinute,
    ));
  });

  void _toggleDay(int index, int day, {required bool selected}) =>
      setState(() {
        final days = _ranges[index].weekdays;
        if (selected) {
          days.add(day);
        } else {
          days.remove(day);
        }
      });

  Future<void> _pick(int index, {required bool start}) async {
    final range = _ranges[index];
    final minute = start ? range.startMinute : range.endMinute;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    );
    if (picked == null || !mounted) return;
    final value = picked.hour * 60 + picked.minute;
    setState(() {
      _ranges[index] = (
        weekdays: range.weekdays,
        startMinute: start ? value : range.startMinute,
        endMinute: start ? range.endMinute : value,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < _ranges.length; index++)
              _RangeCard(
                index: index,
                range: _ranges[index],
                onToggleDay: (day, {required selected}) =>
                    _toggleDay(index, day, selected: selected),
                onPickStart: () => _pick(index, start: true),
                onPickEnd: () => _pick(index, start: false),
                onRemove: _ranges.length > 1
                    ? () => setState(() => _ranges.removeAt(index))
                    : null,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addRange,
                icon: const Icon(Icons.add),
                label: Text(l10n.addTimeRange),
              ),
            ),
            if (widget.lists.isNotEmpty)
              ListTile(
                contentPadding: EdgeInsets.zero,
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
                ranges: [
                  for (final range in _ranges)
                    (
                      weekdays: Set.of(range.weekdays),
                      startMinute: range.startMinute,
                      endMinute: range.endMinute,
                    ),
                ],
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

/// One range of the editor: weekday chips, start and end.
class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.index,
    required this.range,
    required this.onToggleDay,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onRemove,
  });

  final int index;
  final _RangeDraft range;
  final void Function(int day, {required bool selected}) onToggleDay;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  /// Null while it is the only range.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final remove = onRemove;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var day = 1; day <= 7; day++)
                  FilterChip(
                    key: ValueKey('range-$index-day-$day'),
                    label: Text(weekdayName(day, locale)),
                    selected: range.weekdays.contains(day),
                    onSelected: (selected) =>
                        onToggleDay(day, selected: selected),
                  ),
              ],
            ),
            Row(
              children: [
                TextButton(
                  key: ValueKey('range-$index-start'),
                  onPressed: onPickStart,
                  child: Text(
                    '${l10n.focusTimeStart} '
                    '${minuteOfDayText(range.startMinute, locale)}',
                  ),
                ),
                TextButton(
                  key: ValueKey('range-$index-end'),
                  onPressed: onPickEnd,
                  child: Text(
                    '${l10n.focusTimeEnd} '
                    '${minuteOfDayText(range.endMinute, locale)}',
                  ),
                ),
                const Spacer(),
                if (remove != null)
                  IconButton(
                    tooltip: l10n.removeTimeRange,
                    icon: const Icon(Icons.close),
                    onPressed: remove,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
