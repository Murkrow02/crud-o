import 'package:crud_o/resources/resource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'crudo_form_event.dart';
import 'crudo_form_state.dart';

class CrudoFormBloc<TResource extends CrudoResource<TModel>, TModel> extends Bloc<CrudoFormEvent, CrudoFormState> {

  final TResource resource;

  CrudoFormBloc({required this.resource}) : super(FormLoadingState()) {
    on<LoadFormModelEvent<TModel>>(_onLoadFormModel);
    // on<InitFormModel>(_onInitModel);
    // on<UpdateFormModel>(_onUpdateItem);
    // on<CreateFormModel>(_onCreateItem);
  }

  Future<void> _onLoadFormModel(
      LoadFormModelEvent<TModel> event, Emitter<CrudoFormState> emit) async {
    // try {
    //   final item = await resource.repository.getById(event.id);
    //   emit(FormReadyState<TModel>(model: item));
    // } catch (e,s) {
    //   emit(FormErrorState(error: TracedError(e, s)));
    // }
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
