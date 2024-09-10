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
