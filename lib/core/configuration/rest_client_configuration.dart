class RestClientConfiguration
{
  final String baseUrl;
  final int timeoutSeconds;
  // function to return headers, to pass from constructor
  Future<Map<String, String>> Function()? getHeaders;
  RestClientConfiguration({required this.baseUrl, this.timeoutSeconds = 10, this.getHeaders = _defaultHeaders});
  static Future<Map<String, String>> _defaultHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }
}

