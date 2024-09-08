/*
*  This class is used to store an error and its stack trace.
* Useful to know where the error was thrown even if it is caught in a different place.
*/
import 'package:flutter/foundation.dart';

class TracedError
{
  final dynamic error;
  final StackTrace stackTrace;

  TracedError(this.error, this.stackTrace);


  @override
  String toString() {
    return kReleaseMode ? error.toString() : "$error\n$stackTrace";
  }
}