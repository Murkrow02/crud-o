import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/auth/bloc/crudo_auth_wrapper_event.dart';
import 'package:crud_o/auth/bloc/crudo_auth_wrapper_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/*
* CrudoAuthWrapper is a widget that wraps the entire application and checks if the user is logged in or not.
 */
class CrudoAuthWrapper extends StatelessWidget {


  /// Widget to render if the user is logged in
  final Widget loggedIn;

  /// Widget to render if the user is not logged in
  final Widget loggedOut;

  /// Widget shown while checking if the user is logged in
  final Widget? checkingAuth;

  /// Builds the loggedIn widget if the user is logged in, otherwise builds the loggedOut widget.
  /// While checking if the user is logged in, the checkingAuth widget is shown.
  final Future<bool> Function() authCheck;

  /// Called just before showing the logout widget
  final Function onLogout;


  const CrudoAuthWrapper(
      {super.key,
      required this.loggedIn,
      required this.loggedOut,
      required this.authCheck,
      required this.onLogout,
      this.checkingAuth});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CrudoAuthWrapperBloc(),
      child: BlocBuilder<CrudoAuthWrapperBloc, CrudoAuthWrapperState>(
        builder: (context, state) {
          if (state is AuthenticatedState) {
            return loggedIn;
          } else if (state is UnauthenticatedState) {
            onLogout();
            return loggedOut;
          } else {

            // Check if the user is logged in and dispatch the appropriate event
            authCheck().then((loggedIn) {
              if (loggedIn) {
                context.read<CrudoAuthWrapperBloc>().add(LoginEvent());
              } else {
                context.read<CrudoAuthWrapperBloc>().add(LogoutEvent());
              }
            });

            // While waiting for the auth check to complete, show the checkingAuth widget
            return checkingAuth ?? const Scaffold(body: Center());
          }
        },
      ),
    );

    // return FutureBuilder<bool>(
    //   future: loggedInWhen(),
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.done) {
    //       if (snapshot.hasError) {
    //         throw snapshot.error!;
    //       }
    //       if (snapshot.data == true) {
    //         return loggedIn;
    //       } else {
    //         return loggedOut;
    //       }
    //     } else {
    //       return checkingAuth ?? const Scaffold(body: Center());
    //     }
    //   },
    // );
  }
}
