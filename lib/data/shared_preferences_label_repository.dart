import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/focus_label.dart';
import '../domain/label_repository.dart';

/// Stores labels as versioned JSON (`labels.v1`) with a running id counter,
/// so ids are never reused after a label was deleted.
class SharedPreferencesLabelRepository implements LabelRepository {
  SharedPreferencesLabelRepository(this._preferences);

  static const key = 'labels.v1';
  static const _version = 1;

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
        label.id == id ? FocusLabel(id: id, name: name) : label,
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

  ({List<FocusLabel> labels, int nextId}) _load() {
    final stored = _preferences.getString(key);
    if (stored == null) return (labels: const [], nextId: 1);
    return switch (jsonDecode(stored)) {
      {
        'v': _version,
        'nextId': final int nextId,
        'labels': final List<Object?> list,
      } =>
        (
          labels: [
            for (final item in list)
              switch (item) {
                {'id': final String id, 'name': final String name} =>
                  FocusLabel(id: id, name: name),
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
          for (final label in labels) {'id': label.id, 'name': label.name},
        ],
      }),
    );
    _changes.add(labels);
  }
}
