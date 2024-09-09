import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'crudo_form_event.dart';
import 'crudo_form_state.dart';

class CrudoFormBloc<TResource extends CrudoResource<TModel>, TModel extends Object> extends Bloc<CrudoFormEvent, CrudoFormState> {

  final TResource resource;

  CrudoFormBloc({required this.resource}) : super(FormInitialState()) {
    on<LoadFormModelEvent<TModel>>(_onLoadFormModel);
    on<InitFormModelEvent>(_onInitModel);
    // on<UpdateFormModel>(_onUpdateItem);
    // on<CreateFormModel>(_onCreateItem);
  }


  Future<void> _onLoadFormModel(
      LoadFormModelEvent<TModel> event, Emitter<CrudoFormState> emit) async {
    emit(FormLoadingState());
    try {
      final model = await resource.repository.getById(event.id);
      emit(FormReadyState(model: model));
    } catch (e,s) {
      emit(FormErrorState(error: TracedError(e, s)));
    }
  }

  Future<void> _onInitModel(
      InitFormModelEvent event, Emitter<CrudoFormState> emit) async {
    emit(FormReadyState(model: resource.repository.factory.create()));
  }


  //
  // Future<void> _onInitModel(
  //     InitFormModel event, Emitter<FormStateBase> emit) async {
  //   emit(FormReadyState<TModel>(model: repository.createEmpty()));
  // }
  //
  // Future<void> _onUpdateItem(
  //     UpdateFormModel event, Emitter<FormStateBase> emit) async {
  //   try {
  //     final updatedItem = await repository.add(event.model);
  //     //emit(ItemOperationSuccess(item: updatedItem));
  //   } catch (error) {
  //     //emit(ItemError(message: error.toString()));
  //   }
  // }
  //
  // Future<void> _onCreateItem(
  //     CreateFormModel event, Emitter<FormStateBase> emit) async {
  //   try {
  //     final newItem = await repository.add(event.model);
  //     // emit(ItemOperationSuccess(item: newItem));
  //   } on ApiValidationException {
  //     //    emit(ItemApiValidationError(validationException: e, model: event.item));
  //   } catch (e) {
  //     //  emit(ItemError(error: TracedError(e, s)));
  //   }
  // }
}
