import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';

/// The common configuration used for all CrudoFields
///
/// [name] is the name of the field, unique in the form
/// [label] is the label shown on top of the field, if not provided it will default to the name
/// [required] is a flag that indicates if the field is required, will show a validation error if not filled
/// [visible] is a flag that indicates if the field should be rendered
/// [enabled] is a flag that indicates if the field should be enabled to be filled
/// [reactive] is a flag that indicates if the field should trigger a rebuild of the form when the value changes
/// This is used when a field is dependent on another field, for example a dropdown that changes the values of another dropdown
/// [visibleOn] is a list of operations that the field should be visible on
/// [enabledOn] is a list of operations that the field should be enabled on
/// [dependsOn] is a list of fields that this field depends on
/// This means that whenever one of the values of the fields in the list changes, this field should be rebuilt
class CrudoFieldConfiguration {
  final String name;
  final String? label;
  final String? placeholder;
  final bool required;
  final bool visible;
  final bool enabled;
  final bool reactive;
  final List<ResourceOperationType>? visibleOn;
  final List<ResourceOperationType>? enabledOn;
  final List<String>? dependsOn;
  final List<CrudoAction> actions;

  CrudoFieldConfiguration({
    required this.name,
    this.label,
    this.required = false,
    this.enabled = true,
    this.visible = true,
    this.reactive = false,
    this.placeholder,
    this.dependsOn,
    this.visibleOn,
    this.enabledOn,
    this.actions = const [],
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

  bool shouldEnableField(BuildContext context) {
    var resourceContext = context.readResourceContext();
    return enabled &&
        (enabledOn == null ||
            enabledOn!.contains(resourceContext.operationType));
  }

  String getValidationError(BuildContext context) {
    return context.readFormContext().validationErrors[name]?.first ?? '';
  }

  ValueKey? getFieldKey(BuildContext context) {
    if (dependsOn == null) {
      return null;
    }
    return ValueKey(
        dependsOn!.map((e) => context.readFormContext().get(e)).join());
  }

  CrudoFieldConfiguration copyWith({
    String? name,
    String? label,
    bool? required,
    bool? visible,
    bool? enabled,
    bool? reactive,
    List<ResourceOperationType>? visibleOn,
    List<ResourceOperationType>? enabledOn,
    List<String>? dependsOn,
  }) {
    return CrudoFieldConfiguration(
      name: name ?? this.name,
      label: label ?? this.label,
      required: required ?? this.required,
      visible: visible ?? this.visible,
      enabled: enabled ?? this.enabled,
      reactive: reactive ?? this.reactive,
      visibleOn: visibleOn ?? this.visibleOn,
      enabledOn: enabledOn ?? this.enabledOn,
      dependsOn: dependsOn ?? this.dependsOn,
    );
  }
}

InputDecoration defaultDecoration = InputDecoration(
  floatingLabelBehavior: FloatingLabelBehavior.always,
  labelStyle: const TextStyle(color: Colors.grey),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 19.0, horizontal: 10.0),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
);

class CrudoFieldWrapper extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final Widget child;
  final bool errorize;

  const CrudoFieldWrapper(
      {super.key,
      required this.config,
      required this.child,
      this.errorize = true});

  @override
  Widget build(BuildContext context) {

    // Do not render
    if (!config.shouldRenderField(context)) {
      return const SizedBox();
    }

    // Render form component
    return Padding(
      key: config.getFieldKey(context),
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: CrudoErrorize(
                error: errorize ? config.getValidationError(context) : null,
                child:
                    CrudoLabelize(label: config.label ?? config.name, child: child)),
          ),
          if (config.actions.isNotEmpty)
            for (var action in config.actions)
              IconButton(
                icon: Icon(action.icon),
                onPressed: () => action.execute(context),
              ),
        ],
      ),
    );
  }
}

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
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
