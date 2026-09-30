import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_label.dart';

void main() {
  group('FocusLabel', () {
    test('trims the name', () {
      expect(FocusLabel(id: 'l1', name: '  Study ').name, 'Study');
    });

    test('rejects empty names', () {
      expect(() => FocusLabel(id: 'l1', name: '   '), throwsArgumentError);
    });

    test('rejects names longer than 30 characters', () {
      expect(FocusLabel(id: 'l1', name: 'a' * 30).name, hasLength(30));
      expect(() => FocusLabel(id: 'l1', name: 'a' * 31), throwsArgumentError);
    });

    test('compares by id and name', () {
      expect(
        FocusLabel(id: 'l1', name: 'Study'),
        FocusLabel(id: 'l1', name: 'Study'),
      );
      expect(
        FocusLabel(id: 'l1', name: 'Study'),
        isNot(FocusLabel(id: 'l2', name: 'Study')),
      );
    });
  });
}
