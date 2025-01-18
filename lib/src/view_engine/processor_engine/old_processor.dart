import 'package:vania/src/view_engine/template_engine.dart';

import 'abs_processor.dart';

class OldProcessor extends AbsProcessor {
  @override
  String parse(String content, [Map<String, dynamic>? context]) {
    final oldPattern = RegExp(
      r"\{@\s*old\(\s*'([^']*)'\s*\)\s*@\}",
      dotAll: true,
    );
    String? oldKey;
    content = content.replaceAllMapped(oldPattern, (oldMatch) {
      oldKey = oldMatch.group(1);
      return TemplateEngine().formData[oldKey] ?? '';
    });

    if (oldKey != null) {
      TemplateEngine().formData.remove(oldKey);
    }
    return content;
  }
}
