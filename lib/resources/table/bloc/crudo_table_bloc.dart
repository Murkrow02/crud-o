import 'dart:async';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'crudo_table_event.dart';
import 'crudo_table_state.dart';

class CrudoTableBloc<TResource extends CrudoResource<TModel>, TModel> extends Bloc<CrudoTableEvent, CrudoTableState> {

  final TResource resource;

  CrudoTableBloc({required this.resource}) : super(TableInitialState()) {
    on<LoadTableEvent>(_onLoadItems);
    on<UpdateTableEvent>(_onUpdateItems);
  }

  Future<void> _onLoadItems(LoadTableEvent event, Emitter<CrudoTableState> emit) async {
    try {
      emit(TableLoadingState());
      final request = PaginatedRequest(page: 1);  // Define the initial request
      final response = await resource.repository.getPaginated(request: request);
      emit(TableLoadedState<TModel>(response: response, request: request));
    } catch (e, s) {
      emit(TableErrorState(error: TracedError(e, s)));
    }
  }

  FutureOr<void> _onUpdateItems(UpdateTableEvent event, Emitter<CrudoTableState> emit) async
  {
    try {
      emit(TableLoadingState());
      final response = await resource.repository.getPaginated(request: event.request);
      emit(TableLoadedState<TModel>(response: response, request: event.request));
    } catch (e, s) {
      emit(TableErrorState(error: TracedError(e, s)));
    }
  }
}
