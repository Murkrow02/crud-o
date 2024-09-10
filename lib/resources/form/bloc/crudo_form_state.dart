import 'package:crud_o/core/models/traced_error.dart';
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

class FormReadyState extends CrudoFormState {
  final Map<String, dynamic> formData;

  FormReadyState({required this.formData});

  @override
  List<Object> get props => [formData];
}

class FormErrorState extends CrudoFormState {
  final TracedError error;

  FormErrorState({required this.error});

  @override
  List<Object> get props => [error];
}

class FormValidationErrorState extends CrudoFormState {
  final ApiValidationException validationException;
  final Map<String, dynamic> formData;

  FormValidationErrorState({required this.validationException, required this.formData});

  @override
  List<Object> get props => [validationException, formData];
}
