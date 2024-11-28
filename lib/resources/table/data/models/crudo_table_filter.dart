import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:flutter/cupertino.dart';

class CrudoTableFilter<TModel>
{
  String name;
  String label;
  IconData? icon;
  final Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)? filterFunction;

  CrudoTableFilter({
    required this.name,
    required this.label,
    required this.filterFunction,
    this.icon,
  });


}