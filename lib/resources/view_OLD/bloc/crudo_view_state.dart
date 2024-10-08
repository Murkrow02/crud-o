// import 'package:crud_o/core/models/traced_error.dart';
// import 'package:equatable/equatable.dart';
// import 'package:crud_o/core/exceptions/api_validation_exception.dart';
//
// abstract class CrudoViewState extends Equatable {
//   @override
//   List<Object?> get props => [];
// }
//
// class ViewInitialState extends CrudoViewState {}
//
// class ViewLoadingState extends CrudoViewState {}
//
// class ViewReadyState<T extends Object> extends CrudoViewState {
//   final T model;
//   ViewReadyState({required this.model});
//
//   @override
//   List<Object> get props => [model];
// }
//
// class ViewErrorState extends CrudoViewState {
//   final TracedError tracedError;
//
//   ViewErrorState({required this.tracedError});
//
//   @override
//   List<Object> get props => [tracedError];
// }
