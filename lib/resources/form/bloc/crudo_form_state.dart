import 'package:crud_o_core/models/traced_error.dart';
import 'package:crud_o_core/resources/resource_operation_type.dart';
import 'package:equatable/equatable.dart';
import 'package:crud_o_core/exceptions/api_validation_exception.dart';

abstract class CrudoFormState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FormInitialState extends CrudoFormState {}

// Form is in a saved state for a fraction, only to indicate the UI that data has changed
// While in this state form should still show a loading spinner
class FormSavedState<T extends Object> extends CrudoFormState {
  final T model;
  FormSavedState({required this.model});

  @override
  List<Object> get props => [model];
}

class FormLoadingState extends CrudoFormState {}
class FormModelLoadedState<T extends Object> extends CrudoFormState {
  final T model;
  FormModelLoadedState({required this.model});

  @override
  List<Object> get props => [model];
}
class FormReadyState extends CrudoFormState {
  final Map<String, dynamic> formData;
  final Map<String, List<String>>? apiErrors;
  final bool force; /// Forces a rebuild
  final DateTime? timestamp;

  FormReadyState({
    required this.formData,
    this.apiErrors,
    this.force = false
  }) : timestamp = force ? DateTime.now() : null;

  @override
  List<Object?> get props => [formData, timestamp, apiErrors];
}

class FormSavingState extends CrudoFormState {
  final Map<String, dynamic> formData;
  FormSavingState({required this.formData});

  @override
  List<Object> get props => [formData];
}

class FormErrorState extends CrudoFormState {
  final TracedError tracedError;

  FormErrorState({required this.tracedError});

  @override
  List<Object> get props => [tracedError];
}