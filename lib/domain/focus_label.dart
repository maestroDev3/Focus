/// What a session was about, e.g. “Study” or “Work”, optionally with a goal
/// in hours the sessions add up to (#285).
class FocusLabel {
  FocusLabel({
    required this.id,
    required String name,
    this.goal,
    this.weeklyGoal,
  }) : name = name.trim() {
    if (this.name.isEmpty || this.name.length > maxLength) {
      throw ArgumentError.value(name, 'name', 'must be 1–$maxLength characters');
    }
    if (goal case final goal?) {
      if (goal.inMinutes % 60 != 0 ||
          goal.inHours < 1 ||
          goal.inHours > maxGoalHours) {
        throw ArgumentError.value(
          goal,
          'goal',
          'must be 1–$maxGoalHours whole hours',
        );
      }
    }
    if (weeklyGoal case final weekly?) {
      if (weekly.inMinutes % 60 != 0 ||
          weekly.inHours < 1 ||
          weekly.inHours > maxWeeklyGoalHours) {
        throw ArgumentError.value(
          weekly,
          'weeklyGoal',
          'must be 1–$maxWeeklyGoalHours whole hours',
        );
      }
    }
  }

  static const maxLength = 30;
  static const maxGoalHours = 999;

  /// A week has 168 hours.
  static const maxWeeklyGoalHours = 168;

  final String id;
  final String name;

  /// Focus time to reach with this label; null shows only the total.
  final Duration? goal;

  /// Focus time to reach with this label each week (Monday to Sunday), or
  /// none (#337).
  final Duration? weeklyGoal;

  /// This label with [goal] set, or cleared with null.
  FocusLabel withGoal(Duration? goal) =>
      FocusLabel(id: id, name: name, goal: goal, weeklyGoal: weeklyGoal);

  /// This label with [weeklyGoal] set, or cleared with null.
  FocusLabel withWeeklyGoal(Duration? weeklyGoal) =>
      FocusLabel(id: id, name: name, goal: goal, weeklyGoal: weeklyGoal);

  @override
  bool operator ==(Object other) =>
      other is FocusLabel &&
      other.id == id &&
      other.name == name &&
      other.goal == goal &&
      other.weeklyGoal == weeklyGoal;

  @override
  int get hashCode => Object.hash(id, name, goal, weeklyGoal);
}
