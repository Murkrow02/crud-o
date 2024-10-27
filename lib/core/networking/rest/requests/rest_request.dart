class RestRequest
{
  final Map<String, String> queryParameters;
  final String? search;

  RestRequest({
    this.search,
    this.queryParameters = const {},
  });

  String toQueryString()  {
    final queryParameters = {
      if (search != null) 'filter[search]': search.toString(),
    }..addAll(this.queryParameters);
    return Uri(queryParameters: queryParameters).query;
  }
}