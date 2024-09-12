import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/auth/widgets/crudo_auth_wrapper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/crudo_auth_wrapper_event.dart';

extension CrudoAuth on BuildContext {
  void logout() {
    read<CrudoAuthWrapperBloc>().add(LogoutEvent());
  }

  void login() {
    read<CrudoAuthWrapperBloc>().add(LoginEvent());
  }
}