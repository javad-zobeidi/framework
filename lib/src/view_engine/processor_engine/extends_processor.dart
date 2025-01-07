import 'package:vania/src/view_engine/processor_engine/abs_processor.dart';
import 'package:vania/src/view_engine/template_reader.dart';

class ExtendsProcessor implements AbsProcessor {
  /// Parse `{@ extends('template_path') @}` blocks in [content] and replace them with the content of the parent template.
  ///
  /// The parent template path is read from the file system using [FileTemplateReader].
  ///
  /// The following example:
  ///
  @override
  String parse(String content, [Map<String, dynamic>? context]) {
    final extendsPattern = RegExp(r"\{@\s*extends\(\s*'([^']+)'\s*\)\s*@\}");
    final match = extendsPattern.firstMatch(content);
    if (match == null) {
      return content;
    }
    final parentLayoutPath = match.group(1);
    if (parentLayoutPath == null) {
      return content;
    }
    content = content.replaceFirst(extendsPattern, '');
    final parentTemplate = FileTemplateReader().read(parentLayoutPath);
    return parentTemplate;
  }
}
