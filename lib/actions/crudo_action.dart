import 'package:crud_o/resources/form/data/form_result.dart';
import 'package:flutter/material.dart';

/*
*   Generic class to define an action that can be executed in the CRUDO
*   These are typically used in the actions menu of the table
*/
class CrudoAction {
  Function(BuildContext context, Map<String, dynamic>? data) action;
  final String label;
  IconData? icon;
  Color? color;

  CrudoAction(
      {required this.label, this.icon, this.color, required this.action});

  Future<dynamic> execute(BuildContext context, {Map<String, dynamic>? data}) async {
    return await action(context, data);
  }
}
