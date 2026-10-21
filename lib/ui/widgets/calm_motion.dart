import 'package:flutter/widgets.dart';

/// Whether Focus' quiet motion – the breathing ring, the pulses in the
/// background – may run (#306). `FocusApp` turns it on; without a
/// [CalmMotion] above (e.g. in widget tests) and when Android's “Remove
/// animations” is set, everything stays still.
class CalmMotion extends InheritedWidget {
  const CalmMotion({super.key, required this.enabled, required super.child});

  final bool enabled;

  /// True if motion is on here and the system allows animations.
  static bool of(BuildContext context) {
    final motion = context.dependOnInheritedWidgetOfExactType<CalmMotion>();
    final disabled = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return (motion?.enabled ?? false) && !disabled;
  }

  @override
  bool updateShouldNotify(CalmMotion oldWidget) =>
      enabled != oldWidget.enabled;
}
