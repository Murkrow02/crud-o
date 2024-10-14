import 'package:crud_o/resources/resource_context.dart';
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
  final Map<String, dynamic> createData;
  final ResourceContext resourceContext;
  CreateFormModelEvent({required this.formData, required this.createData, required this.resourceContext});

  @override
  List<Object?> get props => [formData, resourceContext];
}

class UpdateFormModelEvent extends CrudoFormEvent {
  final String id;
  final Map<String, dynamic> formData;
  final Map<String, dynamic> updateData;
  UpdateFormModelEvent({required this.id, required this.formData, required this.updateData});

  @override
  List<Object?> get props => [id, formData, updateData];
}

class CustomCreateEvent<T> extends CrudoFormEvent {
  final T model;
  final ResourceContext resourceContext;

  CustomCreateEvent({required this.model, required this.resourceContext});

  @override
  List<Object?> get props => [model, resourceContext];
}

class CustomUpdateEvent<T> extends CrudoFormEvent {
  final T model;
  final ResourceContext resourceContext;

  CustomUpdateEvent({required this.model, required this.resourceContext});

  @override
  List<Object?> get props => [model, resourceContext];
}