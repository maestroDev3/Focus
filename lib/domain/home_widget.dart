/// What the home screen widget needs to show today's progress and to start
/// a session on its own, published by Focus whenever it changes.
class WidgetSnapshot {
  const WidgetSnapshot({
    required this.focus,
    required this.focusedToday,
    required this.dailyGoal,
    this.labelId,
    this.labelName,
  });

  /// Planned duration of a session started from the widget.
  final Duration focus;

  /// Label for a session started from the widget (the one chosen in Focus).
  final String? labelId;
  final String? labelName;

  final Duration focusedToday;
  final Duration dailyGoal;

  @override
  bool operator ==(Object other) =>
      other is WidgetSnapshot &&
      other.focus == focus &&
      other.labelId == labelId &&
      other.labelName == labelName &&
      other.focusedToday == focusedToday &&
      other.dailyGoal == dailyGoal;

  @override
  int get hashCode =>
      Object.hash(focus, labelId, labelName, focusedToday, dailyGoal);

  @override
  String toString() =>
      'WidgetSnapshot(focus: $focus, labelId: $labelId, labelName: '
      '$labelName, focusedToday: $focusedToday, dailyGoal: $dailyGoal)';
}

/// A session the widget started while Focus was closed.
class ExternalStart {
  const ExternalStart({
    required this.start,
    required this.planned,
    this.labelId,
  });

  final DateTime start;
  final Duration planned;
  final String? labelId;
}

/// Connects Focus with the home screen widget.
abstract interface class HomeWidgetBridge {
  /// Hands the widget what it shows and needs for a one-tap start.
  Future<void> publish(WidgetSnapshot snapshot);

  /// The session the widget started since the last call, if any (consumed).
  Future<ExternalStart?> takePendingStart();
}
