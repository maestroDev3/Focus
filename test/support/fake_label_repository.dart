import 'dart:async';

import 'package:focus_timer/domain/focus_label.dart';
import 'package:focus_timer/domain/label_repository.dart';

/// In-memory [LabelRepository] for tests, with the same name rules.
class FakeLabelRepository implements LabelRepository {
  FakeLabelRepository([List<FocusLabel> labels = const []])
    : labels = List.of(labels);

  final List<FocusLabel> labels;
  final _changes = StreamController<List<FocusLabel>>.broadcast();
  var _nextId = 100;

  @override
  Stream<List<FocusLabel>> watchLabels() async* {
    yield List.of(labels);
    yield* _changes.stream;
  }

  @override
  Future<FocusLabel> addLabel(String name) async {
    checkUniqueLabelName(labels, name);
    final label = FocusLabel(id: 'label-${_nextId++}', name: name);
    labels.add(label);
    _changes.add(List.of(labels));
    return label;
  }

  @override
  Future<void> renameLabel(String id, String name) async {
    checkUniqueLabelName(labels, name, exceptId: id);
    final index = labels.indexWhere((label) => label.id == id);
    labels[index] = FocusLabel(id: id, name: name);
    _changes.add(List.of(labels));
  }

  @override
  Future<void> deleteLabel(String id) async {
    labels.removeWhere((label) => label.id == id);
    _changes.add(List.of(labels));
  }
}
