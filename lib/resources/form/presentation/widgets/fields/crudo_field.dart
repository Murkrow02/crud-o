import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';

class CrudoFieldConfiguration {
  final String name;
  final String? label;
  final bool required;
  final bool visible;
  final bool enabled;
  final List<ResourceOperationType>? visibleOn;
  final List<ResourceOperationType>? enabledOn;
  final CrudoViewField Function(
      BuildContext context, String label, String value)? buildViewField;

  CrudoFieldConfiguration({
    required this.name,
    this.label,
    this.required = false,
    this.enabled = true,
    this.visible = true,
    this.visibleOn,
    this.enabledOn,
    this.buildViewField,
  });

  bool shouldRenderField(BuildContext context) {
    var resourceContext = context.readResourceContext();
    return visible &&
        (visibleOn == null ||
            visibleOn!.contains(resourceContext.operationType));
  }

  bool shouldRenderViewField(BuildContext context) {
    var resourceContext = context.readResourceContext();
    return resourceContext.operationType == ResourceOperationType.view &&
        (visibleOn == null ||
            visibleOn!.contains(resourceContext.operationType));
  }

  Widget renderViewField(BuildContext context) {
    var value = context.readFormContext().formData[name]?.toString() ?? '';
    if (buildViewField == null) {
      return CrudoViewField(name: label ?? name, child: Text(value));
    }
    return buildViewField!(context, label ?? name, value);
  }

  bool shouldEnableField(BuildContext context) {
    var resourceContext = context.readResourceContext();
    return enabled &&
        (enabledOn == null ||
            enabledOn!.contains(resourceContext.operationType));
  }

  String getValidationError(BuildContext context) {
    return context.readFormContext().validationErrors[name]?.first ?? '';
  }
}

InputDecoration defaultDecoration = InputDecoration(
  floatingLabelBehavior: FloatingLabelBehavior.always,
  labelStyle: const TextStyle(color: Colors.grey),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
);

class CrudoLabelize extends StatelessWidget {
  final String label;
  final Widget child;
  final double offset;

  const CrudoLabelize(
      {super.key, required this.label, required this.child, this.offset = 10});

  @override
  Widget build(BuildContext context) {
    return Stack(clipBehavior: Clip.none, children: [
      child,
      Positioned(
          top: -offset,
          left: 10,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          )),
    ]);
  }
}

class CrudoErrorize extends StatelessWidget {
  final String? error;
  final Widget child;

  const CrudoErrorize({super.key, required this.error, required this.child});

  @override
  Widget build(BuildContext context) {
    if (error == null || error!.isEmpty) {
      return child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
