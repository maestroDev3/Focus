import 'package:focus_timer/domain/document_store.dart';

/// In-memory [DocumentStore] for tests.
class FakeDocumentStore implements DocumentStore {
  String? savedName;
  String? savedText;

  /// Text returned by [openText]; null simulates a cancelled picker.
  String? textToOpen;

  @override
  Future<bool> saveText(String fileName, String content) async {
    savedName = fileName;
    savedText = content;
    return true;
  }

  @override
  Future<String?> openText() async => textToOpen;
}
