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
  CreateFormModelEvent({required this.model});

  @override
  List<Object?> get props => [model];
}

class UpdateFormModelEvent<T> extends CrudoFormEvent {
  final T model;

  UpdateFormModelEvent({required this.model});

  @override
  List<Object?> get props => [model];
}