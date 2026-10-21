import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/focus_label.dart';
import '../domain/label_repository.dart';
import 'label_codec.dart';

/// Stores labels as versioned JSON (`labels.v2`, with goals) with a running
/// id counter, so ids are never reused after a label was deleted. Labels
/// stored as `labels.v1` (before goals, #285) are read as they are.
class SharedPreferencesLabelRepository implements LabelRepository {
  SharedPreferencesLabelRepository(this._preferences);

  static const key = 'labels.v2';
  static const _legacyKey = 'labels.v1';
  static const _version = 2;

  final SharedPreferences _preferences;
  final _changes = StreamController<List<FocusLabel>>.broadcast();

  @override
  Stream<List<FocusLabel>> watchLabels() async* {
    yield _load().labels;
    yield* _changes.stream;
  }

  @override
  Future<FocusLabel> addLabel(String name) async {
    final (:labels, :nextId) = _load();
    checkUniqueLabelName(labels, name);
    final label = FocusLabel(id: 'label-$nextId', name: name);
    await _save([...labels, label], nextId + 1);
    return label;
  }

  @override
  Future<void> renameLabel(String id, String name) async {
    final (:labels, :nextId) = _load();
    checkUniqueLabelName(labels, name, exceptId: id);
    await _save([
      for (final label in labels)
        label.id == id
            ? FocusLabel(id: id, name: name, goal: label.goal)
            : label,
    ], nextId);
  }

  @override
  Future<void> setGoal(String id, Duration? goal) async {
    final (:labels, :nextId) = _load();
    await _save([
      for (final label in labels) label.id == id ? label.withGoal(goal) : label,
    ], nextId);
  }

  @override
  Future<void> deleteLabel(String id) async {
    final (:labels, :nextId) = _load();
    await _save([
      for (final label in labels)
        if (label.id != id) label,
    ], nextId);
  }

  @override
  Future<void> replaceAll(List<FocusLabel> labels) async {
    // Continue after the highest restored id so new ids never collide.
    var nextId = 1;
    for (final label in labels) {
      final number = int.tryParse(label.id.replaceFirst('label-', ''));
      if (number != null && number >= nextId) nextId = number + 1;
    }
    await _save(List.of(labels), nextId);
  }

  ({List<FocusLabel> labels, int nextId}) _load() {
    final stored =
        _preferences.getString(key) ?? _preferences.getString(_legacyKey);
    if (stored == null) return (labels: const [], nextId: 1);
    return switch (jsonDecode(stored)) {
      {
        'v': 1 || _version,
        'nextId': final int nextId,
        'labels': final List<Object?> list,
      } =>
        (
          labels: [
            for (final item in list)
              switch (item) {
                {'id': final String id, 'name': final String name} =>
                  FocusLabel(
                    id: id,
                    name: name,
                    goal: decodeLabelGoal(item),
                  ),
                _ => throw FormatException('Malformed label: $item'),
              },
          ],
          nextId: nextId,
        ),
      _ => throw FormatException('Unknown labels data: $stored'),
    };
  }

  Future<void> _save(List<FocusLabel> labels, int nextId) async {
    await _preferences.setString(
      key,
      jsonEncode({
        'v': _version,
        'nextId': nextId,
        'labels': [
          for (final label in labels) encodeLabel(label),
        ],
      }),
    );
    _changes.add(labels);
  }
}

