import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_home_widget_bridge.dart';
import 'package:focus_timer/domain/home_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelHomeWidgetBridge.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  Object? pendingAnswer;
  final bridge = MethodChannelHomeWidgetBridge(
    texts: (
      start: 'Focus',
      progress: '{today} of {goal}',
      focusing: 'Focusing',
      focusingWithLabel: 'Focusing · {label}',
      countdownChannel: 'Session countdown',
    ),
    formatDuration: (duration) => '${duration.inMinutes} min',
  );

  setUp(() {
    calls.clear();
    pendingAnswer = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'takePendingStart' ? pendingAnswer : null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelHomeWidgetBridge', () {
    test('publishes the defaults and the formatted progress', () async {
      await bridge.publish(
        const WidgetSnapshot(
          focus: Duration(minutes: 25),
          labelId: 'study',
          labelName: 'Study',
          focusedToday: Duration(minutes: 70),
          dailyGoal: Duration(minutes: 120),
        ),
      );

      expect(calls.single.method, 'publish');
      expect(calls.single.arguments, {
        'focusMinutes': 25,
        'labelId': 'study',
        'progress': '70 min of 120 min',
        'start': 'Focus',
        'countdownTitle': 'Focusing · Study',
        'countdownChannel': 'Session countdown',
      });
    });

    test('uses the plain countdown title without label', () async {
      await bridge.publish(
        const WidgetSnapshot(
          focus: Duration(minutes: 25),
          focusedToday: Duration.zero,
          dailyGoal: Duration(minutes: 120),
        ),
      );

      final arguments = calls.single.arguments as Map;
      expect(arguments['countdownTitle'], 'Focusing');
      expect(arguments['labelId'], isNull);
    });

    test('maps a pending widget start', () async {
      final start = DateTime.utc(2026, 10, 3, 10);
      pendingAnswer = {
        'startMillis': start.millisecondsSinceEpoch,
        'plannedMinutes': 25,
        'labelId': 'study',
      };

      final pending = await bridge.takePendingStart();

      expect(pending?.start.millisecondsSinceEpoch, start.millisecondsSinceEpoch);
      expect(pending?.planned, const Duration(minutes: 25));
      expect(pending?.labelId, 'study');
    });

    test('returns null without a pending start', () async {
      expect(await bridge.takePendingStart(), isNull);
    });
  });
}
