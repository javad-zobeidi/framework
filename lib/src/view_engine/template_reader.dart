import 'dart:io';

/// An interface (abstract class) for reading template files.
abstract class TemplateReader {
  /// Reads the template contents from the given [filePath].
  String read(String filePath);
}

class FileTemplateReader implements TemplateReader {
  static final FileTemplateReader _singleton = FileTemplateReader._internal();
  factory FileTemplateReader() => _singleton;
  FileTemplateReader._internal();

  /// Reads the html template from the given [template] path.
  ///
  /// The template path is relative to the `lib/view/template/` directory.
  /// The template file must end with `.html`.
  ///
  /// Throws a [FileSystemException] if the file does not exist.
  ///
  @override
  String read(String template) {
    final filePath = 'lib/view/template/$template.html';
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FileSystemException('Html template not found', filePath);
    }
    return file.readAsStringSync();
  }
}
