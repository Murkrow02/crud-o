import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_labelize.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';

class CrudoField extends StatelessWidget {
  final Widget Function(BuildContext context, void Function(BuildContext context, dynamic value) onChanged) builder;
  final CrudoFieldConfiguration config;
  const CrudoField({super.key, required this.builder, required this.config});

  @override
  Widget build(BuildContext context) {
    return CrudoFieldWrapper(config: config, child: builder(context, onChanged));
  }

  void onChanged(BuildContext context, dynamic value)
  {
    context.readFormContext().set(config.name, value);
    if (config.reactive) {
      context.readFormContext().rebuild();
    }
    config.onChanged?.call(context, value);
  }
}

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
  final void Function(BuildContext context, dynamic value)? onChanged;

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
    this.onChanged,
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
