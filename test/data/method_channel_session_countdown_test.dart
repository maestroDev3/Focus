import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_session_countdown.dart';
import 'package:focus_timer/domain/session_countdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelSessionCountdown.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  String formatTime(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
  var texts = (
    channelName: 'Session countdown',
    focusing: 'Focusing',
    focusingWithLabel: 'Focusing · {label}',
    paused: 'Paused · {time} left',
    until: 'until {time}',
    formatTime: formatTime,
  );
  final countdown = MethodChannelSessionCountdown(texts: () => texts);

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelSessionCountdown', () {
    test('reads the texts when showing, so a new language applies', () async {
      final english = texts;
      texts = (
        channelName: 'Обратный отсчёт',
        focusing: 'Фокус',
        focusingWithLabel: 'Фокус · {label}',
        paused: 'Пауза · осталось {time}',
        until: 'до {time}',
        formatTime: formatTime,
      );
      addTearDown(() => texts = english);

      await countdown.show(
        CountdownRunning(end: DateTime.utc(2026, 10, 4, 10), labelName: null),
      );

      expect((calls.single.arguments as Map)['title'], 'Фокус');
      expect((calls.single.arguments as Map)['text'], 'до 10:00');
    });

    test('sends the end and the title with the label', () async {
      final end = DateTime.utc(2026, 10, 3, 10, 25);

      await countdown.show(CountdownRunning(end: end, labelName: 'Study'));

      expect(calls.single.method, 'show');
      expect(calls.single.arguments, {
        'channelName': 'Session countdown',
        'title': 'Focusing · Study',
        'paused': false,
        'endMillis': end.millisecondsSinceEpoch,
        'text': 'until 10:25',
      });
    });

    test('names the end time after midnight', () async {
      await countdown.show(
        CountdownRunning(end: DateTime.utc(2026, 10, 4, 0, 10)),
      );

      expect((calls.single.arguments as Map)['text'], 'until 00:10');
    });

    test('uses the plain title without label', () async {
      await countdown.show(CountdownRunning(end: DateTime.utc(2026, 10, 3)));

      expect((calls.single.arguments as Map)['title'], 'Focusing');
    });

    test('sends the remaining time while paused', () async {
      await countdown.show(
        const CountdownPaused(remaining: Duration(minutes: 18, seconds: 42)),
      );

      final arguments = calls.single.arguments as Map;
      expect(arguments['paused'], isTrue);
      expect(arguments['endMillis'], isNull);
      expect(arguments['text'], 'Paused · 18:42 left');
    });

    test('hides the countdown', () async {
      await countdown.hide();

      expect(calls.single.method, 'hide');
    });
  });
}
