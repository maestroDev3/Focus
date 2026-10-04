import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_timer/data/method_channel_app_language_setting.dart';
import 'package:focus_timer/domain/app_language.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannelAppLanguageSetting.channel;
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  String? nativeTag;

  setUp(() {
    calls.clear();
    nativeTag = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return call.method == 'get' ? nativeTag : null;
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  group('MethodChannelAppLanguageSetting', () {
    test('loads the language Android keeps for Focus', () async {
      nativeTag = 'ru';

      final language = await const MethodChannelAppLanguageSetting().load();

      expect(calls.single.method, 'get');
      expect(language, AppLanguage.russian);
    });

    test('loads the system language when Android keeps none', () async {
      final language = await const MethodChannelAppLanguageSetting().load();

      expect(language, AppLanguage.system);
    });

    test('saves the language code', () async {
      await const MethodChannelAppLanguageSetting().save(AppLanguage.german);

      expect(calls.single.method, 'set');
      expect(calls.single.arguments, 'de');
    });

    test('saves the system choice as no language', () async {
      await const MethodChannelAppLanguageSetting().save(AppLanguage.system);

      expect(calls.single.method, 'set');
      expect(calls.single.arguments, isNull);
    });
  });
}
