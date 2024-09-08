import 'package:flutter/material.dart';

class CrudoAction{
  Function(BuildContext context, Map<String, dynamic>? data)? action;
  final String label;
  IconData? icon;
  Color? color;

  CrudoAction({required this.label, this.icon, this.color, this.action});

  void execute(BuildContext context, {Map<String, dynamic>? data}){
    if(action != null){
      action!(context, data);
    }
  }
}