import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_session_end_alarm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelSessionEndAlarm.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  const texts = (
    channelName: 'Session end',
    title: 'Session complete',
    body: 'Time for a break.',
  );

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelSessionEndAlarm', () {
    test('schedules the end as epoch milliseconds with the texts', () async {
      final end = DateTime.utc(2026, 10, 2, 10, 25);

      await const MethodChannelSessionEndAlarm(texts: texts).scheduleAt(end);

      expect(calls.single.method, 'schedule');
      expect(calls.single.arguments, {
        'endMillis': end.millisecondsSinceEpoch,
        'channelName': 'Session end',
        'title': 'Session complete',
        'body': 'Time for a break.',
      });
    });

    test('cancels the pending end notification', () async {
      await const MethodChannelSessionEndAlarm(texts: texts).cancel();

      expect(calls.single.method, 'cancel');
    });
  });
}
