import 'package:crud_o/core/configuration/rest_client_configuration.dart';
import 'package:logger/logger.dart';

class CrudoConfiguration
{
  // RestClient
  static RestClientConfiguration? _restClientConfiguration;
  static void configureRestClient(RestClientConfiguration configuration) =>
      _restClientConfiguration = configuration;
  static RestClientConfiguration rest() {
    if (_restClientConfiguration == null) {
      throw Exception(
          'RestClient not configured, call Crudo.configureRestClient() first');
    }
    return _restClientConfiguration!;
  }

  // Logger
static Logger? _loggerConfiguration;
  static void configureLogger(Logger configuration) =>
      _loggerConfiguration = configuration;
  static Logger logger() {
    return _loggerConfiguration ?? Logger(printer: PrettyPrinter());
  }

}