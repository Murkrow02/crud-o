import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:crud_o_core/models/traced_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ErrorAlert extends StatelessWidget {
  final TracedError tracedError;
  final Logger logger = CrudoConfiguration.logger();


  ErrorAlert(this.tracedError, {super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Si è verificato un errore',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 24)),
                SizedBox(height: 10),
                Visibility(
                  visible: kDebugMode,
                    child: Text(tracedError.error.toString(),
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onError))),
                Visibility(
                  visible: kDebugMode,
                  child: Text(tracedError.stackTrace.toString(),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onError)),
                )
              ],
            )),
      ),
    );
  }
}
