import 'package:eloquent/eloquent.dart';
import 'package:vania/vania.dart';

/// Initializes the application configuration and sets up the database connection if specified.
///
/// This function takes a [config] map, sets it as the application configuration,
/// and checks for a database connection setup. If a database connection is defined,
/// it attempts to set up the database client, logging any `InvalidArgumentException` that occurs.
/// It also iterates through a list of service providers specified in the config,
/// calling `register` and `boot` methods on each to initialize them.

Future<void> initializeConfig(config) async {
  Config().setApplicationConfig = config;

  if (env('DB_CONNECTION') != null) {
    try {
      await DatabaseClient().setup();
    } on InvalidArgumentException catch (e) {
      Logger.log(e.cause.toString(), type: Logger.ERROR);
    }
  }

  List<ServiceProvider> providers = config['providers'];
  for (ServiceProvider provider in providers) {
    await provider.register();
    await provider.boot();
  }
}
