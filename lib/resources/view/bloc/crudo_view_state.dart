import 'package:crud_o/core/models/traced_error.dart';
import 'package:equatable/equatable.dart';
import 'package:crud_o/core/exceptions/api_validation_exception.dart';

abstract class CrudoViewState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ViewInitialState extends CrudoViewState {}

class ViewLoadingState extends CrudoViewState {}

class ViewReadyState<T extends Object> extends CrudoViewState {
  final Map<String, dynamic> previewFields;
  ViewReadyState({required this.previewFields});

  @override
  List<Object> get props => [previewFields];
}

class ViewErrorState extends CrudoViewState {
  final TracedError error;

  ViewErrorState({required this.error});

  @override
  List<Object> get props => [error];
}
