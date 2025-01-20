import 'dart:convert';

import 'package:vania/src/utils/helper.dart';

import 'abs_processor.dart';

class TranslateProcessor implements AbsProcessor {
  @override
  String parse(String content, [Map<String, dynamic>? context]) {
    final translatePattern = RegExp(
      r"\{\@\s*trans\(\s*'([^']+)'\s*(?:,\s*({[^}]+}))?\s*\)\s*\@\}",
      dotAll: true,
    );

    return content.replaceAllMapped(translatePattern, (match) {
      final key = match.group(1) ?? '';
      Map<String, dynamic> args;
      try {
        args = jsonDecode(match.group(2)!);
      } catch (e) {
        print(e);
        args = {};
      }
      return trans(key, args);
    });
  }
}
