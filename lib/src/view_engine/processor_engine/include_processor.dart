import 'dart:convert';

import 'package:vania/src/view_engine/processor_engine/abs_processor.dart';
import 'package:vania/src/view_engine/template_engine.dart';
import 'package:vania/src/view_engine/template_reader.dart';

class IncludeProcessor implements AbsProcessor {
  /// Replaces `{@ include <file name> [, <json data>] @}` blocks in [content] with the
  /// rendered content of the included file.
  ///
  /// The included file is read from the file system using the [FileTemplateReader]
  /// and rendered using [TemplateEngine] with a context that includes the
  /// variables from [context] as well as any additional data passed in the
  /// include tag.
  ///
  /// The additional data is expected to be a JSON object and is merged with
  /// the context from [context].
  ///
  /// The included file's content is then replaced in the original content
  /// at the location of the include tag.
  ///
  /// The following example:
  ///
  @override
  String parse(String content, [Map<String, dynamic>? context]) {
    final includePattern = RegExp(
      r"\{@\s*include\(\s*'([^']+)'\s*(,\s*(\{.*?\}))?\)\s*@\}",
      dotAll: true,
    );

    return content.replaceAllMapped(includePattern, (match) {
      final filePath = match.group(1) ?? '';

      final rawData = match.group(3) ?? '';

      final childContext = _parseIncludeData(rawData);
      final mergedContext = {...context ?? {}, ...childContext};

      final includedTemplate = FileTemplateReader().read(filePath);
      return TemplateEngine().renderString(includedTemplate, mergedContext);
    });
  }

  Map<String, dynamic> _parseIncludeData(String dataString) {
    dataString = dataString.trim();
    if (dataString.isEmpty) return {};

    try {
      final decoded = jsonDecode(dataString);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return {};
  }
}
