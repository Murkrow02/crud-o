import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:equatable/equatable.dart';
import 'package:crud_o/core/exceptions/api_validation_exception.dart';

abstract class CrudoFormState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FormInitialState extends CrudoFormState {}

// Form is in a saved state for a fraction, only to indicate the UI that data has changed
// While in this state form should still show a loading spinner
class FormSavedState extends CrudoFormState {}
class FormLoadingState extends CrudoFormState {}
class FormModelLoadedState<T extends Object> extends CrudoFormState {
  final T model;
  FormModelLoadedState({required this.model});

  @override
  List<Object> get props => [model];
}
class FormReadyState extends CrudoFormState {
  final Map<String, dynamic> formData;
  final ResourceOperationType operationType;
  FormReadyState({required this.formData, required this.operationType});

  @override
  List<Object> get props => [formData, operationType];
}
class FormSavingState extends CrudoFormState {
  final Map<String, dynamic> formData;
  FormSavingState({required this.formData});

  @override
  List<Object> get props => [formData];
}
class FormNotValidState extends CrudoFormState {
  final Map<String, dynamic> oldFormData;
  final Map<String, List<dynamic>> formErrors;
  final List<String> nonFormErrors;

  FormNotValidState(
      {required this.oldFormData, required this.formErrors, required this.nonFormErrors});

  @override
  List<Object> get props => [oldFormData, formErrors, nonFormErrors];
}

class FormErrorState extends CrudoFormState {
  final TracedError tracedError;

  FormErrorState({required this.tracedError});

  @override
  List<Object> get props => [tracedError];
}