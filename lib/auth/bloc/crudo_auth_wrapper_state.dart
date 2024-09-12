import 'package:equatable/equatable.dart';

abstract class CrudoAuthWrapperState extends Equatable {}

class CheckingAuthState extends CrudoAuthWrapperState {
  @override
  List<Object> get props => [];
}

class AuthenticatedState extends CrudoAuthWrapperState {
  @override
  List<Object> get props => [];
}

class UnauthenticatedState extends CrudoAuthWrapperState {
  @override
  List<Object> get props => [];
}