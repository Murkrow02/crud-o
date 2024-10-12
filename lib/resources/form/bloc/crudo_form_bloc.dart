import 'dart:async';

import 'package:crud_o/core/exceptions/api_validation_exception.dart';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
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
    on<RebuildFormEvent>(_onReloadForm);
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
      emit(FormSavedState());
      emit(FormModelLoadedState(model: apiModel));
    } on ApiValidationException catch (e) {
      _handleApiValidationException(emit, event.formData, e);
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
      emit(FormSavedState());
      event.resourceContext.operationType = ResourceOperationType.edit;
      event.resourceContext.id = resource.getId(apiModel);
      emit(FormModelLoadedState(model: apiModel));
    } on ApiValidationException catch (e) {
      _handleApiValidationException(emit, event.formData, e);
    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }
  }

  // Called when the api returns a validation error
  void _handleApiValidationException(
    Emitter<CrudoFormState> emit,
    Map<String, dynamic> formData,
    ApiValidationException e,
  ) {
    final formErrors = <String, List<String>>{};
    final globalErrors = <String>[];

    e.errors.forEach((key, value) {

      // The form contains the error key
      if (formData.containsKey(key)) {
        formErrors[key] = value;
      } else {
        globalErrors.addAll(value);
      }
    });

    emit(FormNotValidState(
        oldFormData: formData,
        formErrors: formErrors,
        nonFormErrors: globalErrors));
  }

  Future<void> _onReloadForm(RebuildFormEvent event, Emitter<CrudoFormState> emit) async {
    emit(FormReadyState(formData: event.formData));
  }
}
