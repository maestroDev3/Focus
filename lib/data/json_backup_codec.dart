import 'dart:convert';

import '../domain/backup.dart';
import 'backup_codec.dart';

/// Backup files as pretty-printed JSON.
class JsonBackupCodec implements BackupCodec {
  const JsonBackupCodec();

  @override
  String encode(Backup backup) =>
      const JsonEncoder.withIndent('  ').convert(encodeBackup(backup));

  @override
  Backup decode(String text) {
    final Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw const FormatException('This file is not JSON.');
    }
    if (json is! Map<String, Object?>) {
      throw const FormatException('This file is not a Focus backup.');
    }
    return decodeBackup(json);
  }
}
