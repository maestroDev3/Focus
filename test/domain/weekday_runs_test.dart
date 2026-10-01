import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/focus_time.dart';

void main() {
  group('weekdayRuns', () {
    test('groups consecutive weekdays', () {
      expect(weekdayRuns({1, 2, 3, 4, 5}), [(1, 5)]);
      expect(weekdayRuns({6, 7}), [(6, 7)]);
      expect(weekdayRuns({1, 3, 4, 5, 7}), [(1, 1), (3, 5), (7, 7)]);
    });
  });
}
