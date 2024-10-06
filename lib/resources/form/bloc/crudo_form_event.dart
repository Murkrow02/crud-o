import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:equatable/equatable.dart';

abstract class CrudoFormEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFormModelEvent extends CrudoFormEvent {
  final String id;
  LoadFormModelEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

/// Builds the form with the given data to re-paint UI with new data
class RebuildFormEvent<T> extends CrudoFormEvent {
  final Map<String, dynamic> formData;
  RebuildFormEvent({required this.formData});

  @override
  List<Object?> get props => [formData];
}

class InitFormModelEvent extends CrudoFormEvent {
  @override
  List<Object?> get props => [];
}

class CreateFormModelEvent extends CrudoFormEvent {
  final Map<String, dynamic> formData;
  CreateFormModelEvent({required this.formData});

  @override
  List<Object?> get props => [formData];
}

class UpdateFormModelEvent extends CrudoFormEvent {
  final String id;
  final Map<String, dynamic> formData;

  UpdateFormModelEvent({required this.id, required this.formData});

  @override
  List<Object?> get props => [id, formData];
}