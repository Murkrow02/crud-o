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
  List<Object?> get props => [formData, force ? DateTime.now().millisecondsSinceEpoch : null];
}

class InitFormModelEvent extends CrudoFormEvent {
  @override
  List<Object?> get props => [];
}

class CreateFormModelEvent<T> extends CrudoFormEvent {
  final Map<String, dynamic> formData;
  final Map<String, dynamic> createData;
  final ResourceContext resourceContext;
  CreateFormModelEvent({required this.formData, required this.createData, required this.resourceContext});

  @override
  List<Object?> get props => [formData, resourceContext, createData];
}

class UpdateFormModelEvent<T> extends CrudoFormEvent {
  final String id;
  final Map<String, dynamic> formData;
  final Map<String, dynamic> updateData;
  UpdateFormModelEvent({required this.id, required this.formData, required this.updateData});

  @override
  List<Object?> get props => [id, formData, updateData];
}

class CustomCreateEvent<T> extends CrudoFormEvent {
  final Future<T> createFunction;
  final Map<String, dynamic> formData;
  CustomCreateEvent({required this.createFunction, required this.formData});

  @override
  List<Object?> get props => [createFunction, formData];
}

class CustomUpdateEvent<T> extends CrudoFormEvent {
  final Future<T> updateFunction;
  final Map<String, dynamic> formData;
  CustomUpdateEvent({required this.updateFunction, required this.formData});

  @override
  List<Object?> get props => [updateFunction, formData];
}