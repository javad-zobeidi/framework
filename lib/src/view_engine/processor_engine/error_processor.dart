import 'package:vania/src/view_engine/template_engine.dart';

import 'abs_processor.dart';

class ErrorProcessor extends AbsProcessor {
  @override
  String parse(String content, [Map<String, dynamic>? context]) {
    String? errorKey;
    final hasErrorPattern = RegExp(
      r"hasError\(\s*'([^']*)'\s*\)",
      dotAll: true,
    );
    content = content.replaceAllMapped(hasErrorPattern, (match) {
      errorKey = match.group(1);
      return TemplateEngine().sessionErrors.containsKey(errorKey).toString();
    });

    final errorPattern = RegExp(
      r"\{@\s*error\(\s*'([^']*)'\s*\)\s*@\}",
      dotAll: true,
    );

    content = content.replaceAllMapped(errorPattern, (error) {
      errorKey = error.group(1);
      return TemplateEngine().sessionErrors[errorKey] ?? '';
    });

    return content;
  }
}
