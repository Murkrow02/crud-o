import 'package:crud_o/core/exceptions/api_validation_exception.dart';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/view/bloc/crudo_view_event.dart';
import 'package:crud_o/resources/view/bloc/crudo_view_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class CrudoViewBloc<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends Bloc<CrudoViewEvent, CrudoViewState> {
  final TResource resource;

  CrudoViewBloc({required this.resource}) : super(ViewInitialState()) {
    on<LoadViewEvent<TModel>>(_onLoadViewEvent);
  }

  Future<void> _onLoadViewEvent(
      LoadViewEvent<TModel> event, Emitter<CrudoViewState> emit) async {
    emit(ViewLoadingState());
    try {
      final model = await resource.repository.getById(event.id);
      emit(ViewReadyState<TModel>(previewFields: resource.repository.serializer.serializeToView(model)));
    } catch (e, s) {
      emit(ViewErrorState(tracedError: TracedError(e, s)));
    }
  }
}
