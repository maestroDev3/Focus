import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/day_part.dart';

void main() {
  group('dayPartOf', () {
    DateTime at(int hour, [int minute = 0]) =>
        DateTime(2026, 9, 29, hour, minute);

    test('is morning from 05:00 to 11:59', () {
      expect(dayPartOf(at(5)), DayPart.morning);
      expect(dayPartOf(at(11, 59)), DayPart.morning);
    });

    test('is afternoon from 12:00 to 17:59', () {
      expect(dayPartOf(at(12)), DayPart.afternoon);
      expect(dayPartOf(at(17, 59)), DayPart.afternoon);
    });

    test('is evening from 18:00 to 04:59', () {
      expect(dayPartOf(at(18)), DayPart.evening);
      expect(dayPartOf(at(23, 59)), DayPart.evening);
      expect(dayPartOf(at(0, 1)), DayPart.evening);
      expect(dayPartOf(at(4, 59)), DayPart.evening);
    });
  });
}
