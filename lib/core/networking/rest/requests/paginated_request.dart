import 'package:crud_o/core/networking/rest/requests/rest_request.dart';

class PaginatedRequest extends RestRequest
{
  final int page;
  final String? search;
  final String? orderBy;

  PaginatedRequest({
    required this.page,
    this.search,
    this.orderBy,
    super.queryParameters = const {},
  });


  @override
  String toQueryString() {
    final queryParameters = {
      'page': page.toString(),
      if (search != null) 'search': search.toString(),
      if (orderBy != null) 'orderBy': orderBy.toString(),
    }..addAll(super.queryParameters);
    return Uri(queryParameters: queryParameters).query;
  }

  PaginatedRequest copyWith({
    int? page,
    String? search,
    String? orderBy,
  }) {
    return PaginatedRequest(
      page: page ?? this.page,
      search: search ?? this.search,
      orderBy: orderBy ?? this.orderBy,
    );
  }
}