import 'package:crud_o/resources/form/data/crudo_field_entry.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_fields.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    // // Detect if preview
    // if (config.shouldRenderViewField(context)) {
    //   var rawDate = context.readFormContext().get<DateTime?>(config.name);
    //   var formattedDate = rawDate != null
    //       ? DateFormat(format?.pattern ?? getDefaultFormat().pattern)
    //       .format(rawDate)
    //       : '';
    //   return CrudoViewField(
    //       config: config,
    //       child: Text(formattedDate));
    // }

    return CrudoField(
      config: config,
      editModeBuilder: (context, onChanged) => DateTimeField(
        decoration: defaultDecoration,
        enabled: config.shouldEnableField(context),
        onChanged: (DateTime? value) => onChanged(context, value),
        initialValue: context.readFormContext().get(config.name) as DateTime?,
        format: format ?? getDefaultFormat(),
        onShowPicker: (BuildContext context, DateTime? currentValue) {
          return showDatePicker(
            context: context,
            firstDate: DateTime(1900),
            initialDate: currentValue ?? DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365 * 100)),
          );
        },
      ),
    );

    // CrudoFieldWrapper(
    //   errorize: false,
    //   config: config,
    //   child: DateTimePickerType(
    //     onChanged: (value) {
    //       context.readFormContext().set(config.name, value);
    //       if (config.reactive) {
    //         context.readFormContext().rebuild();
    //       }
    //     },
    //     name: config.name,
    //     format: format ?? getDefaultFormat(),
    //     inputType: inputType == DateTimePickerType.date
    //         ? InputType.date
    //         : inputType == DateTimePickerType.time
    //         ? InputType.time
    //         : InputType.both,
    //     enabled: config.shouldEnableField(context),
    //     initialValue: context.readFormContext().get(config.name) as DateTime?,
    //     validator: FormBuilderValidators.compose([
    //       if (config.required) FormBuilderValidators.required(
    //           errorText: TempLang.requiredField),
    //     ]),
    //     decoration: defaultDecoration,
    //   ));
  }

  DateFormat getDefaultFormat() {
    return inputType == DateTimePickerType.date
        ? DateFormat('dd-MM-yyyy')
        : DateFormat('dd-MM-yyyy HH:mm:ss');
  }
}

enum DateTimePickerType { date, time, both }
