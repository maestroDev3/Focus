import 'package:flutter/services.dart';

import '../domain/app_language.dart';

/// Keeps the app language on Android: from Android 13 as the per-app
/// language that the Android settings show too, before that in the app's
/// own preferences.
class MethodChannelAppLanguageSetting implements AppLanguageSetting {
  const MethodChannelAppLanguageSetting();

  static const channel = MethodChannel('de.maestrodev.focus_timer/language');

  @override
  Future<AppLanguage> load() async {
    final tag = await channel.invokeMethod<String>('get');
    return AppLanguage.fromLanguageCode(tag?.split(RegExp('[-_]')).first);
  }

  @override
  Future<void> save(AppLanguage language) =>
      channel.invokeMethod<void>('set', language.languageCode);
}
