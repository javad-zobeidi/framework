import 'package:vania/src/container.dart';
import 'package:vania/src/ioc_container.dart';
import 'package:vania/src/localization_handler/localization.dart';
import 'package:vania/src/server/base_http_server.dart';
import 'package:vania/vania.dart';

import 'http/request/request_handler.dart';
import 'http/session/session_manager.dart';

class Application extends Container {
  static Application? _singleton;

  factory Application() {
    if (_singleton == null) {
      _singleton = Application._internal();
      Env().load();
      Localization().init();
    }
    return _singleton!;
  }

  Application._internal();

  late BaseHttpServer _server;

  Future<void> initialize({required Map<String, dynamic> config}) async {
    IoCContainer().register<RequestHandler>(() => RequestHandler());
    IoCContainer()
        .register<SessionManager>(() => SessionManager(), singleton: true);
    if (env('APP_KEY') == '' || env('APP_KEY') == null) {
      throw Exception('Key not found');
    }

    _server = BaseHttpServer(config: config);
    _server.startServer();
  }

  Future<void> close() async {
    _server.httpServer?.close();
  }
}
