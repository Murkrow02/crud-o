import 'package:crud_o/resources/form/data/form_context.dart';
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

    if(config.reactive)
      throw Exception('CrudoDatetimeField does not yet support reactive fields');

    if (!config.shouldRenderField(context)) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Builder(builder: (context) {

        // Detect if preview
        if(config.shouldRenderViewField(context)) {
          return config.renderViewField(context);
        }


        return FormBuilderDateTimePicker(name: config.name,
          enabled: config.shouldEnableField(context),
          initialValue: context.readFormContext().get(config.name) as DateTime? ?? DateTime.now(),
          validator: FormBuilderValidators.compose([
            if (config.required) FormBuilderValidators.required(),
          ]),
          decoration: defaultDecoration.copyWith(labelText: config.label),
        );

      }),
    );
  }
}
