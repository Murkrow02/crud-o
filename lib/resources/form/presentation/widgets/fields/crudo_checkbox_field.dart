import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/data/crudo_field.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';

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
          config: config,
          child: Text(
              context.readFormContext().get(config.name) == true ? 'Si' : 'No'));
    }

    // Edit or create
    return CrudoFieldWrapper(
        config: config,
        child: Checkbox(
          // name: config.name,
          // enabled: config.shouldEnableField(context),
          onChanged: (value) {
            context.readFormContext().set(config.name, value ?? false);
            if(config.reactive) {
              context.readFormContext().rebuild();
            }
            config.onChanged?.call(context, value);
          },
          value: context.readFormContext().get(config.name) == true,
        ));
  }
}
