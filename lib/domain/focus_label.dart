/// What a session was about, e.g. “Study” or “Work”.
class FocusLabel {
  FocusLabel({required this.id, required String name}) : name = name.trim() {
    if (this.name.isEmpty || this.name.length > maxLength) {
      throw ArgumentError.value(name, 'name', 'must be 1–$maxLength characters');
    }
  }

  static const maxLength = 30;

  final String id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is FocusLabel && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}
