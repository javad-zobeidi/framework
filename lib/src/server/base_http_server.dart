import 'dart:io';
import 'dart:isolate';

import 'package:vania/src/http/request/request_handler.dart';
import 'package:vania/vania.dart';

import 'initialize_config.dart';
import 'isolate/isolate_handler.dart';
import 'isolate/http_isolate.dart';

class BaseHttpServer {
  final Map<String, dynamic> config;

  BaseHttpServer({required this.config});

  final _isolates = <Isolate>[];

  HttpServer? httpServer;

  /// The entry point for each isolate. This function is called once per isolate.
  ///
  /// The [args] parameter is a list of two elements: the first is an [IsolateHandler]
  /// instance, which is used to create a new instance of the HTTP server. The
  /// second is a [SendPort], which is used to send errors back to the main
  /// isolate.
  ///
  /// If an error occurs while running the HTTP server, the error is sent back to
  /// the main isolate on the given [SendPort].
  void isolateEntryPoint(List<Object> args) async {
    final handler = args[0] as IsolateHandler;
    final sendPort = args[1] as SendPort;
    try {
      await httpIsolate(handler, sendPort, config);
    } catch (e, stackTrace) {
      sendPort.send(
        'Error in isolate entry point ${Isolate.current.debugName}: $e\n$stackTrace',
      );
    }
  }

  /// Spawns a number of isolates and starts the HTTP server in each one.
  ///
  /// This is the entry point for the HTTP server. The server is started in each
  /// isolate, and the [IsolateHandler] is used to create a new instance of the
  /// server.
  ///
  /// The [IsolateHandler] is created with the following configuration:
  ///
  /// - host: The host to listen on. Defaults to '127.0.0.1'.
  /// - port: The port to listen on. Defaults to 8000.
  /// - shared: Whether to share the port with other isolates. Defaults to false.
  /// - secure: Whether to use HTTPS. Defaults to false.
  /// - certficate: The path to the SSL certificate.
  /// - privateKey: The path to the private key.
  /// - privateKeyPassword: The password for the private key.
  ///
  /// The [ReceivePort] is used to receive messages from the isolates. The
  /// received messages are printed to the console.
  Future<void> spawnIsolates(int numIsolates) async {
    IsolateHandler isolateHandler = IsolateHandler(
      host: env<String>('APP_HOST', '127.0.0.1'),
      port: env<int>('APP_PORT', 8000),
      shared: env<bool>('APP_SHARED', false),
      secure: env<bool>('APP_SECURE', false),
      certficate: env<String>('APP_CERTIFICATE'),
      privateKey: env<String>('APP_PRIVATE_KEY'),
      privateKeyPassword: env<String>('APP_PRIVATE_KEY_PASSWORD'),
    );

    final receivePort = ReceivePort();

    for (int i = 0; i < numIsolates; i++) {
      final isolate = await Isolate.spawn(
        isolateEntryPoint,
        [isolateHandler, receivePort.sendPort],
        debugName: 'Isolate Id $i',
      );
      _isolates.add(isolate);
    }

    receivePort.listen(print);
  }

  void killAll() {
    for (Isolate isolate in _isolates) {
      isolate.kill();
    }
    _isolates.clear();
  }

  /// Starts the HTTP server with the current configuration.
  ///
  /// If the application is configured to use a secure connection, the server
  /// will be started using HTTPS with the provided certificate and private key.
  /// Otherwise, it will start an HTTP server.
  ///
  /// The server listens for incoming HTTP requests using the `httpRequestHandler`.
  ///
  /// If the `APP_DEBUG` environment variable is set to true, the server's URL
  /// will be printed to the console.
  ///
  /// An optional [onError] callback can be provided to handle server start errors.
  ///
  /// Returns a [Future] that completes with the started [HttpServer] instance.
  ///
  /// Throws an error if the server fails to start.

  Future<HttpServer> startServer({
    Function? onError,
  }) async {
    try {
      await initializeConfig(config);
      if (env<bool>('APP_SECURE', false)) {
        var certificateChain = env<String>('APP_CERTIFICATE');
        var serverKey = env<String>('APP_PRIVATE_KEY');
        var password = env<String>('APP_PRIVATE_KEY_PASSWORD');

        var context = SecurityContext()
          ..useCertificateChain(certificateChain)
          ..usePrivateKey(serverKey, password: password);

        httpServer = await HttpServer.bindSecure(
          env<String>('APP_HOST', '127.0.0.1'),
          env<int>('APP_PORT', 8000),
          context,
          shared: env<bool>('APP_SHARED', false),
        );
      } else {
        httpServer = await HttpServer.bind(
          env<String>('APP_HOST', '127.0.0.1'),
          env<int>('APP_PORT', 8000),
          shared: env<bool>('APP_SHARED', false),
        );
      }

      httpServer?.listen(httpRequestHandler);

      if (env<bool>('APP_DEBUG')) {
        if (env<bool>('APP_SECURE')) {
          print("Server started on https://127.0.0.1:${env('APP_PORT')}");
        } else {
          print("Server started on http://127.0.0.1:${env('APP_PORT')}");
        }
      }
      return httpServer!;
    } catch (e) {
      print('Error starting server : $e');
      rethrow;
    }
  }
}
