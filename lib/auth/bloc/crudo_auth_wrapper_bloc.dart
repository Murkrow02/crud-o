import 'package:flutter_bloc/flutter_bloc.dart';

import 'crudo_auth_wrapper_event.dart';
import 'crudo_auth_wrapper_state.dart';

class CrudoAuthWrapperBloc extends Bloc<CrudoAuthWrapperEvent, CrudoAuthWrapperState> {


  CrudoAuthWrapperBloc() : super(CheckingAuthState())
  {
    on<LoginEvent>((event, emit) {
      emit(AuthenticatedState());
    });
    on<LogoutEvent>((event, emit) {
      emit(UnauthenticatedState());
    });
  }

}