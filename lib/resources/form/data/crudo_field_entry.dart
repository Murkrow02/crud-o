
import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';


class CrudoFieldEntry
{
  final String name;
  dynamic _value;
  List<String> _errors = [];

  CrudoFieldEntry(this.name);

  dynamic get value => _value;
  set value(dynamic value) => _value = value;
}
