import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/shared_preferences_label_repository.dart';
import 'package:focus_timer/domain/focus_label.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late SharedPreferencesLabelRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = SharedPreferencesLabelRepository(preferences);
  });

  List<String> names(List<FocusLabel> labels) => [
    for (final label in labels) label.name,
  ];

  group('SharedPreferencesLabelRepository', () {
    test('emits added labels in insertion order', () async {
      final emitted = <List<String>>[];
      final subscription = repository.watchLabels().listen(
        (labels) => emitted.add(names(labels)),
      );
      addTearDown(subscription.cancel);

      await Future<void>.delayed(Duration.zero);
      await repository.addLabel('Study');
      await repository.addLabel('Work');
      await Future<void>.delayed(Duration.zero);

      expect(emitted.last, ['Study', 'Work']);
      expect(emitted.first, isEmpty);
    });

    test('rejects duplicate names ignoring case', () async {
      final study = await repository.addLabel('Study');
      await repository.addLabel('Work');

      expect(() => repository.addLabel('study'), throwsArgumentError);
      expect(
        () => repository.renameLabel(study.id, 'WORK'),
        throwsArgumentError,
      );
    });

    test('renames a label, also to another case of its own name', () async {
      final study = await repository.addLabel('Study');

      await repository.renameLabel(study.id, 'Deep work');
      await repository.renameLabel(study.id, 'DEEP work');

      expect(names(await repository.watchLabels().first), ['DEEP work']);
    });

    test('deletes a label', () async {
      final study = await repository.addLabel('Study');
      await repository.addLabel('Work');

      await repository.deleteLabel(study.id);

      expect(names(await repository.watchLabels().first), ['Work']);
    });

    test('gives every label a new id, also after deleting', () async {
      final first = await repository.addLabel('Study');
      await repository.deleteLabel(first.id);
      final second = await repository.addLabel('Work');

      expect(second.id, isNot(first.id));
    });

    test('persists labels for a new instance', () async {
      await repository.addLabel('Study');

      final reopened = SharedPreferencesLabelRepository(preferences);

      expect(names(await reopened.watchLabels().first), ['Study']);
    });

    test('rejects an unknown stored version', () async {
      SharedPreferences.setMockInitialValues({'labels.v1': '{"v":5}'});
      final broken = SharedPreferencesLabelRepository(
        await SharedPreferences.getInstance(),
      );

      expect(broken.watchLabels().first, throwsFormatException);
    });

    test('replaces all labels and keeps ids unique afterwards', () async {
      await repository.addLabel('Old');

      await repository.replaceAll([
        FocusLabel(id: 'label-7', name: 'Study'),
        FocusLabel(id: 'label-3', name: 'Work'),
      ]);
      final added = await repository.addLabel('Reading');

      expect(names(await repository.watchLabels().first), [
        'Study',
        'Work',
        'Reading',
      ]);
      expect(added.id, 'label-8');
    });
  });
}
