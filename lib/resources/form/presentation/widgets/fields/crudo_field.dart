import 'package:crud_o/resources/form/data/form_context_container.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';


abstract class CrudoField extends StatelessWidget {

  final String name;
  final String? label;
  final bool required;
  final bool visible;
  final List<ResourceOperationType>? visibleOn;
  final List<ResourceOperationType>? enabledOn;
  const CrudoField({
    super.key,
    required this.name,
    this.label,
    this.required = false,
    this.visible = true,
    this.visibleOn,
    this.enabledOn,
  });

  Widget build(BuildContext context){

    // Get context container
    var formContext = context.readFormContext();

    // Should render this field?
    if(!visible || (visibleOn != null && !visibleOn!.contains(formContext.operationType))){
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: buildField(context),
    );
  }

  Widget buildField(BuildContext context);
}

InputDecoration defaultDecoration = InputDecoration(
  floatingLabelBehavior:FloatingLabelBehavior.always,
  labelStyle: const TextStyle(color: Colors.grey),
  filled: true,
  fillColor: Colors.white,
  contentPadding:
  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide.none),
);
