import 'package:equatable/equatable.dart';
import 'package:crud_o/core/exceptions/api_validation_exception.dart';

abstract class CrudoFormState extends Equatable {
  @override
  List<Object?> get props => [];
}

class FormLoadingState extends CrudoFormState {}

class FormReadyState<T extends Object> extends CrudoFormState {
  final T model;

  FormReadyState({required this.model});

  @override
  List<Object> get props => [model];
}

class FormErrorState extends CrudoFormState {
  final Object error;

  FormErrorState({required this.error});

  @override
  List<Object> get props => [error];
}

class FormValidationErrorState<T extends Object> extends CrudoFormState {
  final ApiValidationException validationException;
  final T model;

  FormValidationErrorState({required this.validationException, required this.model});

  @override
  List<Object?> get props => [validationException, model];
}

