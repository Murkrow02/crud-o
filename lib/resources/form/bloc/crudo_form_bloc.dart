import 'package:crud_o/core/exceptions/api_validation_exception.dart';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'crudo_form_event.dart';
import 'crudo_form_state.dart';

class CrudoFormBloc<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends Bloc<CrudoFormEvent, CrudoFormState> {
  final TResource resource;

  CrudoFormBloc({required this.resource}) : super(FormInitialState()) {
    on<LoadFormModelEvent<TModel>>(_onLoadFormModel);
    on<InitFormModelEvent>(_onInitModel);
    on<UpdateFormModelEvent>(_onUpdateItem);
    on<CreateFormModelEvent>(_onCreateItem);
  }

  Future<void> _onLoadFormModel(
      LoadFormModelEvent<TModel> event, Emitter<CrudoFormState> emit) async {
    emit(FormLoadingState());
    try {
      final model = await resource.repository.getById(event.id);
      emit(FormReadyState(
          formData: resource.repository.serializer.serializeToFormData(model)));
    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }
  }

  Future<void> _onInitModel(
      InitFormModelEvent event, Emitter<CrudoFormState> emit) async {
    emit(FormReadyState(
        formData: resource.repository.serializer
            .serializeToFormData(resource.repository.factory.create())));
  }

  Future<void> _onUpdateItem(
      UpdateFormModelEvent event, Emitter<CrudoFormState> emit) async {
    try {
      emit(FormLoadingState());
      var apiModel = await resource.repository
          .update(resource.repository.factory.createFromFormData(event.formData), event.id);
      emit(FormSavedState());
      emit(FormReadyState(formData: resource.repository.serializer.serializeToFormData(apiModel)));
    } on ApiValidationException catch (e) {
      emit(FormValidationErrorState(
          validationException: e, formData: event.formData));
    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }
  }

  Future<void> _onCreateItem(
      CreateFormModelEvent event, Emitter<CrudoFormState> emit) async {
    try {
      emit(FormLoadingState());
      var apiModel = await resource.repository
          .add(resource.repository.factory.createFromFormData(event.formData));
      emit(FormSavedState());
      emit(FormReadyState(formData: resource.repository.serializer.serializeToFormData(apiModel)));
    } on ApiValidationException catch (e) {
      emit(FormValidationErrorState(
          validationException: e, formData: event.formData));
    } catch (e, s) {
      emit(FormErrorState(tracedError: TracedError(e, s)));
    }
  }
}
