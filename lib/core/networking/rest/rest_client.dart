import 'dart:convert';
import 'package:crud_o/core/exceptions/api_validation_exception.dart';
import 'package:crud_o/core/exceptions/rest_exception.dart';
import 'package:crud_o/core/networking/rest/requests/rest_request.dart';
import 'package:crud_o/core/networking/rest/rest_client_configuration.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

class RestClient {

  // Logger instance
  final logger = Logger(printer: PrettyPrinter());

  // Configuration
  static RestClientConfiguration? _configuration;

  static void configure(RestClientConfiguration configuration) =>
      _configuration = configuration;

  RestClientConfiguration get configuration {
    if (_configuration == null) {
      throw Exception(
          'RestClient not configured, call RestClient.configure() first');
    }
    return _configuration!;
  }

  // Build final uri with parameters
  Uri _buildUri(String endpoint, RestRequest? request) {
    String url = configuration.baseUrl;
    return Uri.parse(
        '$url/$endpoint${request != null ? '?${request.toQueryString()}' : ''}');
  }

  // Function to perform a GET request
  Future<dynamic> get(String endpoint, {RestRequest? request}) async {
    Uri uri = _buildUri(endpoint, request);
    logger.d("GET: $uri");
    final response = await http
        .get(
        uri,
          headers: await configuration.getHeaders!(),
        )
        .timeout(Duration(seconds: configuration.timeoutSeconds));
    return handleResponseAndDecodeBody(response);
  }

  // Function to perform a PUT request
  Future<dynamic> put(String endpoint, dynamic data, {RestRequest? request}) async {
    Uri uri = _buildUri(endpoint, request);
    logger.d("PUT: $uri");
    final response = await http
        .put(
        uri,
          body: jsonEncode(data),
          headers: await configuration.getHeaders!(),
        )
        .timeout(Duration(seconds: configuration.timeoutSeconds));
    return handleResponseAndDecodeBody(response);
  }

  // Function to perform a POST request
  Future<dynamic> post(String endpoint, dynamic data, {RestRequest? request}) async {
    Uri uri = _buildUri(endpoint, request);
    logger.d("POST: $uri");
    final response = await http
        .post(
        uri,
          body: jsonEncode(data),
          headers: await configuration.getHeaders!(),
        )
        .timeout(Duration(seconds: configuration.timeoutSeconds));
    return handleResponseAndDecodeBody(response);
  }

  // Function to perform a DELETE request
  Future<dynamic> delete(String endpoint, {RestRequest? request}) async {
    Uri uri = _buildUri(endpoint, request);
    logger.d("DELETE: $uri");
    final response = await http
        .delete(
        uri,
          headers: await configuration.getHeaders!(),
        )
        .timeout(Duration(seconds: configuration.timeoutSeconds));
    return handleResponseAndDecodeBody(response);
  }


  // Generic response handler, returns response as dynamic after decoding and handling errors
  Future<dynamic> handleResponseAndDecodeBody(
      http.Response response) async {
    // Internal server error
    if (response.statusCode == 500) {
      logger.e("Request: ${response.request?.url} failed. \n ${response.body}");
      throw RestException(
          "Internal server error, please try again later", response.statusCode);
    }

    // Decode response body
    dynamic decodedBody = json.decode(response.body);

    // Validation error, throw exception that will be handled in UI
    if (response.statusCode == 422) {
      var errors = Map<String, List<dynamic>>.from(decodedBody['errors']);
      throw ApiValidationException(errors);
    }

    // Check if need to show message in toast
    String? message = decodedBody['message'];

    // Error
    if (response.statusCode != 200 && response.statusCode != 201) {
      // Display error message
      if (message != null && message.isNotEmpty) {
        Toaster.error(message);
      }
      throw RestException(message ?? "An error occurred", response.statusCode);
    }

    // Display success message
    if (message != null && message.isNotEmpty) Toaster.success(message);

    // No data? Throw exception as response is not well formatted
    if (decodedBody['data'] == null) {
      throw RestException(
          "Response is not well formatted", response.statusCode);
    }

    return decodedBody;
  }


}
