import 'package:vania/src/http/session/session_manager.dart';
import 'package:vania/src/ioc_container.dart';
import 'package:vania/src/view_engine/processor_engine/abs_processor.dart';

class CsrfProcessor implements AbsProcessor {
  @override
  String parse(String content, [Map<String, dynamic>? context]) {
    final csrfPattern = RegExp(
      r"\{@\s*csrf\s*@\}",
      dotAll: true,
    );
    return content.replaceAllMapped(csrfPattern, (match) {
      String csrfToken = IoCContainer().resolve<SessionManager>().csrfToken;
      return '<input type="hidden" name="_csrf" value="$csrfToken">';
    });
  }
}
