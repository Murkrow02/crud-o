import 'package:equatable/equatable.dart';

abstract class CrudoFormEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadFormModelEvent<T> extends CrudoFormEvent {
  final String id;

  LoadFormModelEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class InitFormModelEvent extends CrudoFormEvent {
  @override
  List<Object?> get props => [];
}

class CreateFormModelEvent<T> extends CrudoFormEvent {
  final T model;
  final Map<String, dynamic> formData;
  CreateFormModelEvent({required this.model, required this.formData});

  @override
  List<Object?> get props => [model, formData];
}

class UpdateFormModelEvent<T> extends CrudoFormEvent {
  final T model;
  final String id;
  final Map<String, dynamic> formData;

  UpdateFormModelEvent({required this.model, required this.id, required this.formData});

  @override
  List<Object?> get props => [model, id, formData];
}