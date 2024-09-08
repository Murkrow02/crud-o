import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/resource.dart';
import 'package:equatable/equatable.dart';

abstract class CrudoTableState extends Equatable {

  @override
  List<Object> get props => [];
}

class TableInitialState extends CrudoTableState {}
class TableLoadingState extends CrudoTableState {}


class TableLoadedState<TModel> extends CrudoTableState {
  final PaginatedResourceResponse<TModel> response;
  final PaginatedRequest request;

  TableLoadedState({
    required this.response,
    required this.request,
  });

  @override
  List<Object> get props => [response, request];
}

class TableErrorState extends CrudoTableState {
  final TracedError error;

  TableErrorState({required this.error});

  @override
  List<Object> get props => [error];
}