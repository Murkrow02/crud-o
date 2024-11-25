import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';

import 'crudo_field.dart';

class CrudoDatetimeField extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final DateFormat? format;
  final DateTimePickerType inputType;

  const CrudoDatetimeField({
    super.key,
    required this.config,
    this.format,
    this.inputType = DateTimePickerType.both,
  });

  @override
  Widget build(BuildContext context) {
    if (config.reactive)
      throw Exception(
          'CrudoDatetimeField does not yet support reactive fields');

    // Detect if preview
    if (config.shouldRenderViewField(context)) {
      var rawDate = context.readFormContext().get<DateTime?>(config.name);
      var formattedDate = rawDate != null
          ? DateFormat(format?.pattern ?? getDefaultFormat().pattern)
          .format(rawDate)
          : '';
      return CrudoViewField(
          config: config,
          child: Text(formattedDate));
    }

    return CrudoFieldWrapper(
        errorize: false,
        config: config,
        child: FormBuilderDateTimePicker(
          onChanged: (value) {
            context.readFormContext().set(config.name, value);
            if (config.reactive) {
              context.readFormContext().rebuild();
            }
          },
          name: config.name,
          format: format ?? getDefaultFormat(),
          inputType: inputType == DateTimePickerType.date
              ? InputType.date
              : inputType == DateTimePickerType.time
              ? InputType.time
              : InputType.both,
          enabled: config.shouldEnableField(context),
          initialValue: context.readFormContext().get(config.name) as DateTime?,
          validator: FormBuilderValidators.compose([
            if (config.required) FormBuilderValidators.required(
                errorText: TempLang.requiredField),
          ]),
          decoration: defaultDecoration,
        ));
  }

  DateFormat getDefaultFormat() {
    return inputType == DateTimePickerType.date
        ? DateFormat('dd-MM-yyyy')
        : DateFormat('dd-MM-yyyy HH:mm:ss');
  }
}
enum DateTimePickerType { date, time, both }

