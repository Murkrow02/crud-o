import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'crudo_field.dart';

class CrudoDatetimeField extends StatelessWidget {
  final CrudoFieldConfiguration config;

  const CrudoDatetimeField({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    if (config.reactive)
      throw Exception(
          'CrudoDatetimeField does not yet support reactive fields');

    // Detect if preview
    if (config.shouldRenderViewField(context)) {
      return CrudoViewField(
          name: config.name,
          child: Text(context.readFormContext().get(config.name).toString() ?? ''));
    }

    return CrudoFieldWrapper(
        errorize: false,
        config: config,
        child: FormBuilderDateTimePicker(
          name: config.name,
          enabled: config.shouldEnableField(context),
          initialValue: context.readFormContext().get(config.name) as DateTime?,
          validator: FormBuilderValidators.compose([
            if (config.required) FormBuilderValidators.required(),
          ]),
          decoration: defaultDecoration,
        ));
  }
}
