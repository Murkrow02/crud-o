import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:equatable/equatable.dart';
import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';

abstract class CrudoTableEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTableEvent extends CrudoTableEvent {}

class UpdateTableEvent extends CrudoTableEvent {
  final PaginatedRequest request;
  UpdateTableEvent({required this.request});

  @override
  List<Object?> get props => [request];
}