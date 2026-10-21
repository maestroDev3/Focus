import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Opens a calm bottom sheet with two wheels – hours and minutes in
/// [stepMinutes] steps – and returns the chosen duration on “Done”, or null
/// when dismissed (#287, #288). The result always lies within [min]–[max];
/// [initial] is rounded to the nearest step.
Future<Duration?> showDurationWheel(
  BuildContext context, {
  required String title,
  required Duration initial,
  required Duration min,
  required Duration max,
  int stepMinutes = 5,
}) => showModalBottomSheet<Duration>(
  context: context,
  showDragHandle: true,
  // Sized to its content, so the wheels never get squeezed.
  isScrollControlled: true,
  builder: (context) => _DurationWheelSheet(
    title: title,
    initial: _rounded(initial, stepMinutes, min, max),
    min: min,
    max: max,
    stepMinutes: stepMinutes,
  ),
);

/// [value] rounded to the nearest [step] minutes, within [min]–[max].
Duration _rounded(Duration value, int step, Duration min, Duration max) {
  final minutes = (value.inMinutes / step).round() * step;
  final clamped = minutes.clamp(min.inMinutes, max.inMinutes);
  return Duration(minutes: clamped);
}

class _DurationWheelSheet extends StatefulWidget {
  const _DurationWheelSheet({
    required this.title,
    required this.initial,
    required this.min,
    required this.max,
    required this.stepMinutes,
  });

  final String title;
  final Duration initial;
  final Duration min;
  final Duration max;
  final int stepMinutes;

  @override
  State<_DurationWheelSheet> createState() => _DurationWheelSheetState();
}

class _DurationWheelSheetState extends State<_DurationWheelSheet> {
  late var _hours = widget.initial.inHours;
  late var _minutes = widget.initial.inMinutes % 60;

  void _done() {
    final chosen = Duration(hours: _hours, minutes: _minutes);
    final clamped = Duration(
      minutes: chosen.inMinutes.clamp(
        widget.min.inMinutes,
        widget.max.inMinutes,
      ),
    );
    Navigator.of(context).pop(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: _Wheel.itemExtent * 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: _Wheel.itemExtent,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Wheel(
                          key: const Key('wheel-hours'),
                          values: [
                            for (var h = 0; h <= widget.max.inHours; h++) h,
                          ],
                          initial: _hours,
                          label: (hours) => l10n.durationHours(hours),
                          onChanged: (hours) => _hours = hours,
                        ),
                      ),
                      Expanded(
                        child: _Wheel(
                          key: const Key('wheel-minutes'),
                          values: [
                            for (
                              var m = 0;
                              m < 60;
                              m += widget.stepMinutes
                            )
                              m,
                          ],
                          initial: _minutes,
                          label: (minutes) => l10n.durationMinutes(minutes),
                          onChanged: (minutes) => _minutes = minutes,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _done, child: Text(l10n.done)),
            ),
          ],
        ),
      ),
    );
  }
}

/// One wheel of whole values; turning it or tapping a value selects it.
class _Wheel extends StatefulWidget {
  const _Wheel({
    super.key,
    required this.values,
    required this.initial,
    required this.label,
    required this.onChanged,
  });

  static const itemExtent = 40.0;

  final List<int> values;
  final int initial;
  final String Function(int value) label;
  final ValueChanged<int> onChanged;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final _controller = FixedExtentScrollController(
    initialItem: widget.values
        .indexOf(widget.initial)
        .clamp(0, widget.values.length - 1),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: _Wheel.itemExtent,
      diameterRatio: 1.6,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) => widget.onChanged(widget.values[index]),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.values.length,
        builder: (context, index) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _controller.animateToItem(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          ),
          child: Center(
            child: Text(
              widget.label(widget.values[index]),
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }
}

