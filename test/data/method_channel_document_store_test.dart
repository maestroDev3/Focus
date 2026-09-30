import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_document_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelDocumentStore.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return switch (call.method) {
        'saveText' => true,
        'openText' => '{"focusBackup":1}',
        _ => null,
      };
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelDocumentStore', () {
    test('saves text under a file name', () async {
      expect(
        await const MethodChannelDocumentStore().saveText('a.json', '{}'),
        isTrue,
      );
      expect(calls.single.method, 'saveText');
      expect(calls.single.arguments, {'fileName': 'a.json', 'content': '{}'});
    });

    test('opens text from a picked file', () async {
      expect(
        await const MethodChannelDocumentStore().openText(),
        '{"focusBackup":1}',
      );
    });
  });
}
