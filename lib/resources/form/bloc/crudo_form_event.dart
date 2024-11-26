import 'package:crud_o/resources/form/presentation/widgets/crudo_form.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

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
class RebuildFormEvent extends CrudoFormEvent {
  final Map<String, dynamic> formData;
  final bool force;
  RebuildFormEvent({required this.formData, this.force = false});

  @override
  List<Object?> get props => [formData, force];
}

class InitFormModelEvent extends CrudoFormEvent {
  @override
  List<Object?> get props => [];
}

class CreateFormModelEvent<T> extends CrudoFormEvent {
  final Map<String, dynamic> formData;
  final Map<String, dynamic> createData;
  final ResourceContext resourceContext;
  final CrudoFormSaveAction saveAction;
  CreateFormModelEvent({required this.formData, required this.createData, required this.resourceContext, required this.saveAction});

  @override
  List<Object?> get props => [formData, resourceContext, createData, saveAction];
}

class UpdateFormModelEvent<T> extends CrudoFormEvent {
  final String id;
  final Map<String, dynamic> formData;
  final Map<String, dynamic> updateData;
  final CrudoFormSaveAction saveAction;
  UpdateFormModelEvent({required this.id, required this.formData, required this.updateData, required this.saveAction});

  @override
  List<Object?> get props => [id, formData, updateData, saveAction];
}

class CustomCreateEvent<T> extends CrudoFormEvent {
  final Future<T> createFunction;
  final ResourceContext resourceContext;
  final Map<String, dynamic> formData;
  final CrudoFormSaveAction saveAction;
  CustomCreateEvent({required this.createFunction, required this.resourceContext, required this.formData, required this.saveAction});

  @override
  List<Object?> get props => [createFunction, resourceContext, formData, saveAction];
}

class CustomUpdateEvent<T> extends CrudoFormEvent {
  final Future<T> updateFunction;
  final Map<String, dynamic> formData;
  final ResourceContext resourceContext;
  final CrudoFormSaveAction saveAction;
  CustomUpdateEvent({required this.updateFunction, required this.resourceContext, required this.formData, required this.saveAction});

  @override
  List<Object?> get props => [updateFunction, resourceContext, formData, saveAction];
}