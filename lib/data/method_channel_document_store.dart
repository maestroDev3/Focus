import 'package:flutter/services.dart';

import '../domain/document_store.dart';

/// Uses the Android Storage Access Framework (`DocumentChannel.kt`), so no
/// storage permission is needed.
class MethodChannelDocumentStore implements DocumentStore {
  const MethodChannelDocumentStore();

  static const channel = MethodChannel('de.maestrodev.focus_timer/documents');

  @override
  Future<bool> saveText(String fileName, String content) async =>
      await channel.invokeMethod<bool>('saveText', {
        'fileName': fileName,
        'content': content,
      }) ??
      false;

  @override
  Future<String?> openText() => channel.invokeMethod<String>('openText');
}
