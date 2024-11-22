import 'dart:async';

import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/auth/bloc/crudo_auth_wrapper_event.dart';
import 'package:crud_o/auth/bloc/crudo_auth_wrapper_state.dart';
import 'package:crud_o/core/bus/crudo_bus.dart';
import 'package:crud_o/core/bus/events/unauthorized_bus_event.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

/*
* CrudoAuthWrapper is a widget that wraps the entire application and checks if the user is logged in or not.
 */
class CrudoAuthWrapper extends StatefulWidget {
  /// Widget to render if the user is logged in
  final Widget loggedIn;

  /// Widget to render if the user is not logged in
  final Widget loggedOut;

  /// Widget shown while checking if the user is logged in
  final Widget? checkingAuth;

  /// Builds the loggedIn widget if the user is logged in, otherwise builds the loggedOut widget.
  /// While checking if the user is logged in, the checkingAuth widget is shown.
  final Future<bool> Function() authCheck;

  /// Called whenever context.logout() is fired
  final Function onLogout;

  /// Called whenever the RestClient receives Unauthorized response
  final Function(BuildContext context, UnauthorizedBusEvent event)? onUnauthorizedReceived;

  const CrudoAuthWrapper(
      {super.key,
      required this.loggedIn,
      required this.loggedOut,
      required this.authCheck,
      required this.onLogout,
      this.onUnauthorizedReceived,
      this.checkingAuth});

  @override
  State<CrudoAuthWrapper> createState() => _CrudoAuthWrapperState();
}

class _CrudoAuthWrapperState extends State<CrudoAuthWrapper> {
  StreamSubscription<UnauthorizedBusEvent>? _subscription;

  @override
  void dispose() {
    super.dispose();
    if (_subscription != null) {
      _subscription!.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CrudoAuthWrapperBloc(),
      child: BlocBuilder<CrudoAuthWrapperBloc, CrudoAuthWrapperState>(
        builder: (context, state) {
          if (state is AuthenticatedState) {
            _registerUnauthorizedListener(context);
            return widget.loggedIn;
          } else if (state is UnauthenticatedState) {
            widget.onLogout();
            return widget.loggedOut;
          } else {
            // Check if the user is logged in and dispatch the appropriate event
            widget.authCheck().then((loggedIn) {
              if (loggedIn) {
                context.read<CrudoAuthWrapperBloc>().add(LoginEvent());
              } else {
                context.read<CrudoAuthWrapperBloc>().add(LogoutEvent());
              }
            });

            // While waiting for the auth check to complete, show the checkingAuth widget
            return widget.checkingAuth ?? const Scaffold(body: Center());
          }
        },
      ),
    );
  }

  void _registerUnauthorizedListener(BuildContext context) {
    _subscription ??= crudoEventBus.on<UnauthorizedBusEvent>().listen((event) {
        widget.onUnauthorizedReceived?.call(context, event);
      });
  }
}
