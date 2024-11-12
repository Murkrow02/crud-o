import 'package:crud_o/core/networking/rest/requests/rest_request.dart';

class PaginatedRequest extends RestRequest
{
  final int page;
  final SortParameter? sortBy;

  PaginatedRequest({
    required this.page,
    this.sortBy,
    super.search,
    super.queryParameters = const {},
  });


  @override
  String toQueryString() {
    final queryParameters = {
      'page': page.toString(),
      if (search != null) 'filter[search]': search.toString(),
      if (sortBy != null)
        'sort': (sortBy!.direction == SortDirection.asc ? '' : '-') + sortBy!.field,
    }..addAll(super.queryParameters);

    return Uri(queryParameters: queryParameters).query;
  }

  PaginatedRequest copyWith({
    int? page,
    String? search,
    SortParameter? sortBy,
  }) {
    return PaginatedRequest(
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
      search: search ?? this.search,
    );
  }
}

class SortParameter
{
  final String field;
  final SortDirection direction;
  SortParameter(this.field, this.direction);
}
enum SortDirection { asc, desc }
