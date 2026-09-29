import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/domain/countdown.dart';

void main() {
  group('formatCountdown', () {
    test('shows minutes and seconds with two digits', () {
      expect(formatCountdown(const Duration(minutes: 25)), '25:00');
      expect(formatCountdown(const Duration(minutes: 4, seconds: 7)), '04:07');
      expect(formatCountdown(Duration.zero), '00:00');
    });

    test('adds hours for an hour or more', () {
      expect(
        formatCountdown(const Duration(hours: 1, minutes: 5, seconds: 9)),
        '1:05:09',
      );
    });

    test('rounds partial seconds up so 0:00 only shows at the end', () {
      expect(
        formatCountdown(const Duration(minutes: 24, milliseconds: 500)),
        '24:01',
      );
    });
  });
}
