/*
*  This class is used to store an error and its stack trace.
* Useful to know where the error was thrown even if it is caught in a different place.
*/
import 'package:crud_o/core/configuration/crudo_configuration.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class TracedError
{
  final dynamic error;
  final StackTrace stackTrace;
  final Logger logger = CrudoConfiguration.logger();


  TracedError(this.error, this.stackTrace)
  {
    // Log error
    logger.e(this.toString());
  }


  @override
  String toString() {
    return kReleaseMode ? error.toString() : "$error\n$stackTrace";
  }
}