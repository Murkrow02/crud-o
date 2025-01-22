import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:flutter/cupertino.dart';

class CrudoTableFilter<TModel> {
  String name;
  String label;
  IconData? icon;

  /// Completely use a new function to filter the data
  final Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)?
      filterFunction;

  /// Use the same future that the table uses to get the data but with a different request
  final PaginatedRequest? filterRequest;

  CrudoTableFilter({
    required this.name,
    required this.label,
    this.filterFunction,
    this.filterRequest,
    this.icon,
  }) {
    assert(filterFunction != null || filterRequest != null,
        "You must provide a filterFunction or a filterRequest");
    assert(filterFunction == null || filterRequest == null,
        "You can't provide both a filterFunction and a filterRequest");
  }
}
