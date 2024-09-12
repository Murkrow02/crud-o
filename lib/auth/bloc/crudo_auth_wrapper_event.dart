import 'package:equatable/equatable.dart';

abstract class CrudoAuthWrapperEvent extends Equatable {}

class LogoutEvent extends CrudoAuthWrapperEvent {
  @override
  List<Object> get props => [];
}

class LoginEvent extends CrudoAuthWrapperEvent {
  @override
  List<Object> get props => [];
}