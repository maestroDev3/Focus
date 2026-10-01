import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_focus_time_reminders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelFocusTimeReminders.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelFocusTimeReminders', () {
    test('uses the reminders channel', () {
      expect(channel.name, 'de.maestrodev.focus_timer/reminders');
    });

    test('reschedules with the localized texts', () async {
      await MethodChannelFocusTimeReminders().reschedule((
        channelName: 'Focus time reminders',
        title: 'Focus time until {time}',
        body: 'Start a session?',
      ));

      expect(calls.single.method, 'reschedule');
      expect(calls.single.arguments, {
        'channelName': 'Focus time reminders',
        'title': 'Focus time until {time}',
        'body': 'Start a session?',
      });
    });

    test('asks for the notification permission', () async {
      await MethodChannelFocusTimeReminders().requestPermission();

      expect(calls.single.method, 'requestPermission');
    });
  });
}
