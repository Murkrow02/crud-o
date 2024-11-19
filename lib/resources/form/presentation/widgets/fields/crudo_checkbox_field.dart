import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'crudo_field.dart';

class CrudoCheckboxField extends StatelessWidget {
  final CrudoFieldConfiguration config;

  const CrudoCheckboxField({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Detect if preview
    if (config.shouldRenderViewField(context)) {
      return CrudoViewField(
          name: config.label ?? config.name,
          child: Text(
              context.readFormContext().get(config.name) == true ? 'Si' : 'No'));
    }

    // Edit or create
    return CrudoFieldWrapper(
        config: config,
        errorize: false,
        child: FormBuilderCheckbox(
          name: config.name,
          enabled: config.shouldEnableField(context),
          onChanged: (value) {
            if(config.reactive) {
              context.readFormContext().rebuild();
            }
          },
          validator: FormBuilderValidators.compose([
            if (config.required) FormBuilderValidators.required(errorText: TempLang.requiredField),
          ]),
          title: Text(config.placeholder??''),
        ));
  }
}
