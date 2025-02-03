import 'dart:io';

import 'package:vania/vania.dart';

abstract class Middleware {
  Future handle(Request req);
}

abstract class WebSocketMiddleware {
  Future handle(HttpRequest req);
}
