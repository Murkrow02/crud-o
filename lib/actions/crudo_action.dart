import 'package:flutter/material.dart';

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
