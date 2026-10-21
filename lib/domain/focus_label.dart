/// What a session was about, e.g. “Study” or “Work”, optionally with a goal
/// in hours the sessions add up to (#285).
class FocusLabel {
  FocusLabel({required this.id, required String name, this.goal})
    : name = name.trim() {
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
  }

  static const maxLength = 30;
  static const maxGoalHours = 999;

  final String id;
  final String name;

  /// Focus time to reach with this label; null shows only the total.
  final Duration? goal;

  /// This label with [goal] set, or cleared with null.
  FocusLabel withGoal(Duration? goal) =>
      FocusLabel(id: id, name: name, goal: goal);

  @override
  bool operator ==(Object other) =>
      other is FocusLabel &&
      other.id == id &&
      other.name == name &&
      other.goal == goal;

  @override
  int get hashCode => Object.hash(id, name, goal);
}
