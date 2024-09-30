class RestRequest
{
  final Map<String, String> queryParameters;

  RestRequest({
    this.queryParameters = const {},
  });

  String toQueryString() {
    return Uri(queryParameters: queryParameters).query;
  }
}