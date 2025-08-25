import 'dart:async';

import 'package:crud_o_core/exceptions/api_validation_exception.dart';
import 'package:crud_o_core/models/traced_error.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'crudo_form_event.dart';
import 'crudo_form_state.dart';

class CrudoFormBloc<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends Bloc<CrudoFormEvent, CrudoFormState> {
  final TResource resource;

  CrudoFormBloc({required this.resource}) : super(FormInitialState()) {
    on<LoadFormModelEvent>(_onLoadFormModel);
    on<InitFormModelEvent>(_onInitModel);
    on<UpdateFormModelEvent>(_onUpdateItem);
    on<CreateFormModelEvent>(_onCreateItem);
    on<RebuildFormEvent>(_onRebuildForm);
    on<CustomCreateEvent<TModel>>(_onCustomCreate);
    on<CustomUpdateEvent<TModel>>(_onCustomUpdate);
  }

  Future<void> _onLoadFormModel(
      LoadFormModelEvent event, Emitter<CrudoFormState> emit) async {
    emit(FormLoadingState());
    try {
      final model = await resource.repository.getById(event.id);
      emit(FormModelLoadedState(model: model));
    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }
  }

  Future<void> _onInitModel(
      InitFormModelEvent event, Emitter<CrudoFormState> emit) async {
    emit(FormModelLoadedState(model: resource.factory.create()));
  }

  Future<void> _onUpdateItem(
      UpdateFormModelEvent event, Emitter<CrudoFormState> emit) async {
    try {
      emit(FormSavingState(formData: event.formData));
      var apiModel = await resource.repository.update(event.id, event.updateData);
      emit(FormSavedState(model: apiModel));
    } on ApiValidationException catch (e) {
      emit(FormReadyState(formData: event.formData, apiErrors: e.errors, force: true));
    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }
  }

  Future<void> _onCreateItem(
      CreateFormModelEvent event, Emitter<CrudoFormState> emit) async {
    try {

      emit(FormSavingState(formData: event.formData));


      var apiModel = await resource.repository
          .add(event.createData);


      emit(FormSavedState(model: apiModel));


    } on ApiValidationException catch (e) {

      emit(FormReadyState(formData: event.formData, apiErrors: e.errors, force: true));


    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }
  }

  Future<void> _onRebuildForm(RebuildFormEvent event, Emitter<CrudoFormState> emit) async {
    emit(FormReadyState(formData: event.formData, force: event.force));
  }

  FutureOr<void> _onCustomCreate(
      CustomCreateEvent<TModel> event, Emitter<CrudoFormState> emit) async {
    try {
      emit(FormSavingState(formData: event.formData));
      var apiModel = await event.createFunction;
      emit(FormSavedState(model: apiModel));
    } on ApiValidationException catch (e) {
      emit(FormReadyState(formData: event.formData, apiErrors: e.errors, force: true));
    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }

  }

  FutureOr<void> _onCustomUpdate(
      CustomUpdateEvent<TModel> event, Emitter<CrudoFormState> emit) async {
    try {
      emit(FormSavingState(formData: event.formData));
      var apiModel = await event.updateFunction;
      emit(FormSavedState(model: apiModel));
    } on ApiValidationException catch (e) {
      emit(FormReadyState(formData: event.formData, apiErrors: e.errors, force: true));
    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }
  }
}
