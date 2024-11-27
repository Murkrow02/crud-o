import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
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
    return CrudoField(
        config: config,
        builder: (context, onChanged) {
          return CrudoFieldWrapper(
            child: SizedBox(
              height: 55,
              child: Row(
                children: [
                  Checkbox(
                    onChanged: (value) {
                      onChanged(context, value);
                    },
                    value: context.readFormContext().get(config.name) == true,
                  ),
                  if (config.placeholder != null) ...[
                    const SizedBox(width: 10),
                    Text(config.placeholder!)]
                ],
              ),
            ),
          );
        });
  }
}
