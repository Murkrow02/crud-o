import 'dart:convert';
import 'dart:typed_data';
import 'package:crud_o/core/exceptions/api_validation_exception.dart';
import 'package:crud_o/core/exceptions/rest_exception.dart';
import 'package:crud_o/core/exceptions/unauthorized_exception.dart';
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
  Future<dynamic> put(String endpoint, Map<String, dynamic> data,
      {RestRequest? request}) async {
    Uri uri = _buildUri(endpoint, request);
    var validatedData = validateJson(data);
    logger.d("PUT: $uri");
    final response = await http
        .put(
          uri,
          body: jsonEncode(validatedData),
          headers: await configuration.getHeaders!(),
        )
        .timeout(Duration(seconds: configuration.timeoutSeconds));
    return handleResponseAndDecodeBody(response);
  }

  // Function to perform a POST request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data,
      {RestRequest? request}) async {
    Uri uri = _buildUri(endpoint, request);
    logger.d("POST: $uri");
    var validatedData = validateJson(data);
    final response = await http
        .post(
          uri,
          body: jsonEncode(validatedData),
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

  Future<Uint8List?> downloadFileBytes(String url) async {
    logger.d("Downloading file: $url");
    final response = await http.get(
      Uri.parse(url),
      headers: await configuration.getHeaders!(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw RestException("Failed to download file", response.statusCode);
    }
  }

  Future<dynamic> uploadFile(String endpoint, Uint8List data, {RestRequest? request}) async {
    Uri uri = _buildUri(endpoint, request);
    logger.d("Uploading file: $uri");
    final response = await http.post(
      uri,
      headers: await configuration.getHeaders!(),
      body: data,
    );
    return handleResponseAndDecodeBody(response);
  }


  // Generic response handler, returns response as dynamic after decoding and handling errors
  Future<dynamic> handleResponseAndDecodeBody(http.Response response) async {
    // Internal server error
    if (response.statusCode == 500) {
      logger.e("Request: ${response.request?.url} failed. \n ${response.body}");
      throw RestException(
          "Internal server error, please try again later", response.statusCode);
    }

    // Unauthorized
    if (response.statusCode == 401) {
      logger.e("Request: ${response.request?.url} failed. \n ${response.body}");
      throw UnauthorizedException("Unauthorized");
    }

    // Check if response is empty
    if (response.body.isEmpty) {
      return null;
    }

    // Decode response body
    dynamic decodedBody = json.decode(response.body);

    // Validation error, throw exception that will be handled in UI
    if (response.statusCode == 422) {
      Map<String, List<String>> errors = {};
      for (var key in decodedBody['errors'].keys) {
        errors[key] = decodedBody['errors'][key].cast<String>();
      }
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
      throw RestException(
          message != null ? "" : "An error occurred", response.statusCode);
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

  Map<String, dynamic> validateJson(Map<String, dynamic> json) {
    Map<String, dynamic> validatedJson = {};
    json.forEach((key, value) {
      if (value is DateTime) {
        validatedJson[key] = value.toIso8601String();
      } else {
        validatedJson[key] = value;
      }
    });
    return validatedJson;
  }
}
