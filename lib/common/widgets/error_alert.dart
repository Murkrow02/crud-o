import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:crud_o/core/models/traced_error.dart';

class ErrorAlert extends StatelessWidget {

  final TracedError error;
  final Logger logger = Logger(
    printer: PrettyPrinter(),
  );
  ErrorAlert(this.error, {super.key});

  @override
  Widget build(BuildContext context) {

    // Display error
    var displayMessage = kDebugMode ? error.error.toString() : 'Si é verificato un errore';
    return SingleChildScrollView(
      child: Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(displayMessage, style:  TextStyle(color: Theme.of(context).colorScheme.error)),
                Visibility(
                  visible: kDebugMode,
                  child: Text(error.stackTrace.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
                )
              ],
            )
          ),
        ),
      ),
    );
  }
}
