import 'focus_label.dart';

/// Stores the user's labels. Names are unique ignoring case.
abstract interface class LabelRepository {
  /// Emits all labels in insertion order now and after every change.
  Stream<List<FocusLabel>> watchLabels();

  /// Adds a label; throws [ArgumentError] for invalid or duplicate names.
  Future<FocusLabel> addLabel(String name);

  /// Renames a label; throws [ArgumentError] for invalid or duplicate names.
  Future<void> renameLabel(String id, String name);

  /// Deletes a label. Sessions keep its id and count as unlabeled later.
  Future<void> deleteLabel(String id);

  /// Replaces all labels (keeping their ids), e.g. when restoring a backup.
  Future<void> replaceAll(List<FocusLabel> labels);
}

/// Throws [ArgumentError] if another label (not [exceptId]) already has
/// [name], ignoring case and surrounding spaces.
void checkUniqueLabelName(
  List<FocusLabel> labels,
  String name, {
  String? exceptId,
}) {
  final wanted = name.trim().toLowerCase();
  for (final label in labels) {
    if (label.id != exceptId && label.name.toLowerCase() == wanted) {
      throw ArgumentError.value(name, 'name', 'is already used');
    }
  }
}
