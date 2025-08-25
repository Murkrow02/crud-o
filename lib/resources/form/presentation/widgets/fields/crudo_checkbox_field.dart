import 'package:crud_o_core/lang/temp_lang.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:crud_o_core/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';

class CrudoCheckboxField extends StatelessWidget {
  final CrudoFieldConfiguration config;

  const CrudoCheckboxField({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    return CrudoField(
        viewModeValue:
            context.readFormContext().get(config.name) == true ? "Si" : "No",
        config: config,
        editModeBuilder: (context, onChanged) {
          return CrudoFieldWrapper(
            child: SizedBox(
                height: 55,
                child: Row(
                  children: [
                    Checkbox(
                      onChanged: (value) {
                        if (!config.shouldEnableField(context)) {
                          return null;
                        }

                        onChanged(context, value);
                        context.readFormContext().rebuild();
                      },
                      value: context.readFormContext().get(config.name) == true,
                    ),
                    if (config.placeholder != null) ...[
                      const SizedBox(width: 10),
                      Expanded(child: Text(config.placeholder!))
                      //  (child: Text(config.placeholder!))]
                    ],
                  ],
                )),
          );
        });
  }
}
