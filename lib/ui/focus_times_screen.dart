import 'package:flutter/material.dart';

import '../domain/focus_time.dart';
import '../domain/focus_time_repository.dart';
import '../l10n/app_localizations.dart';
import 'focus_time_label.dart';

/// Lets the user plan recurring focus times.
class FocusTimesScreen extends StatelessWidget {
  const FocusTimesScreen({super.key, required this.focusTimes});

  final FocusTimeRepository focusTimes;

  Future<void> _edit(BuildContext context, {FocusTime? time}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final result = await showModalBottomSheet<_FocusTimeDraft>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FocusTimeEditor(initial: time),
    );
    if (result == null) return;
    try {
      // Validates weekdays and length before the overlap check.
      final candidate = FocusTime(
        id: time?.id ?? 'new',
        weekdays: result.weekdays,
        startMinute: result.startMinute,
        endMinute: result.endMinute,
      );
      if (time == null) {
        await focusTimes.addFocusTime(
          weekdays: candidate.weekdays,
          startMinute: candidate.startMinute,
          endMinute: candidate.endMinute,
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
              return ListTile(
                leading: Icon(
                  Icons.schedule,
                  color: theme.colorScheme.primary,
                ),
                title: Text(focusTimeLabel(time, locale)),
                onTap: () => _edit(context, time: time),
                trailing: IconButton(
                  tooltip: l10n.deleteFocusTime,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => focusTimes.deleteFocusTime(time.id),
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
            child: Text(l10n.addFocusTime),
          ),
        ),
      ),
    );
  }
}

/// What the editor returns.
typedef _FocusTimeDraft = ({Set<int> weekdays, int startMinute, int endMinute});

/// Weekday chips and start/end times; defaults to Mon–Fri 09:00–12:00.
class _FocusTimeEditor extends StatefulWidget {
  const _FocusTimeEditor({required this.initial});

  final FocusTime? initial;

  @override
  State<_FocusTimeEditor> createState() => _FocusTimeEditorState();
}

class _FocusTimeEditorState extends State<_FocusTimeEditor> {
  late final _weekdays = {...?widget.initial?.weekdays};
  late var _start = widget.initial?.startMinute ?? 9 * 60;
  late var _end = widget.initial?.endMinute ?? 12 * 60;

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
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop((
                weekdays: Set.of(_weekdays),
                startMinute: _start,
                endMinute: _end,
              )),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
