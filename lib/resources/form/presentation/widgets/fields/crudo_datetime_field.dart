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
    this.inputType = DateTimePickerType.datetime,
  });

  @override
  Widget build(BuildContext context) {

    return CrudoField(
      config: config,
      editModeBuilder: (context, onChanged) => DateTimeField(
        decoration: defaultDecoration(context),
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
          ).then((DateTime? date) async {
            if (date != null) {

              if(inputType == DateTimePickerType.date) {
                context.readFormContext().set(config.name, date);
                return date;
              }

              final time = await showTimePicker(
                context: context,
                initialTime:
                TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
              );
              context.readFormContext().set(config.name, DateTimeField.combine(date, time));
              return DateTimeField.combine(date, time);
            } else {
              return currentValue;
            }
          });
        },
      ),
    );


  }

  DateFormat getDefaultFormat() {
    return inputType == DateTimePickerType.date
        ? DateFormat('dd-MM-yyyy')
        : DateFormat('dd-MM-yyyy HH:mm:ss');
  }
}

enum DateTimePickerType { date, time, datetime }
