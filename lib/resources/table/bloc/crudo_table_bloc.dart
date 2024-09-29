import 'dart:async';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'crudo_table_event.dart';
import 'crudo_table_state.dart';

class CrudoTableBloc<TResource extends CrudoResource<TModel>, TModel> extends Bloc<CrudoTableEvent, CrudoTableState> {

  final TResource resource;
  final Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)? customFuture;
  CrudoTableBloc({required this.resource, this.customFuture}) : super(TableInitialState()){
    on<LoadTableEvent>(_onLoadItems);
    on<UpdateTableEvent>(_onTableParametersUpdated);
  }

  Future<void> _onLoadItems(LoadTableEvent event, Emitter<CrudoTableState> emit) async {
    try {
      emit(TableLoadingState());
      final request = PaginatedRequest(page: 1);  // Define the initial request
      final response = await customFuture?.call(request) ?? await resource.repository.getPaginated(request: request);
      emit(TableLoadedState<TModel>(response: response, request: request));
    } catch (e, s) {
      emit(TableErrorState(tracedError: TracedError(e, s)));
    }
  }

  FutureOr<void> _onTableParametersUpdated(UpdateTableEvent event, Emitter<CrudoTableState> emit) async
  {
    try {
      emit(TableLoadingState());
      final response = await customFuture?.call(event.request) ?? await resource.repository.getPaginated(request: event.request);
      emit(TableLoadedState<TModel>(response: response, request: event.request));
    } catch (e, s) {
      emit(TableErrorState(tracedError: TracedError(e, s)));
    }
  }
}
