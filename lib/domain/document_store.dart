/// Lets the user save and open text files through the system file picker.
abstract interface class DocumentStore {
  /// Asks where to save [content] as [fileName]; false if cancelled.
  Future<bool> saveText(String fileName, String content);

  /// Asks for a file and returns its text, or null if cancelled.
  Future<String?> openText();
}
