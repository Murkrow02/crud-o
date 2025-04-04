import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:crud_o/resources/form/data/crudo_field_entry.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_fields.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CrudoDateRangeField extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final DateFormat? format;
  final CalendarDatePicker2Type calendarType;

  const CrudoDateRangeField({
    super.key,
    required this.config,
    this.format,
    this.calendarType = CalendarDatePicker2Type.range,
  });

  @override
  Widget build(BuildContext context) {
    return CrudoField(
        config: config,
        editModeBuilder: (context, onChanged) => GestureDetector(
            onTap: () => _openDatePicker(context),
            child:
            CrudoFieldWrapper(child:
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: context.readFormContext().get(config.name) == null
                  ? const Text('Seleziona un intervallo di date')
                  : Text(
                      '${DateFormat('dd-MM-yyyy').format((context.readFormContext().get(config.name) as List<DateTime?>)[0] ?? DateTime.now())} - ${DateFormat('dd-MM-yyyy').format((context.readFormContext().get(config.name) as List<DateTime?>)[1] ?? DateTime.now())}'),
            ))));
  }

  void _openDatePicker(BuildContext context) async {
    showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: calendarType,
      ),
      dialogSize: const Size(325, 400),
      borderRadius: BorderRadius.circular(15),
    ).then((List<DateTime?>? values) {

      // Check if the user has selected a date range
      if (values == null || values.isEmpty) {
        return;
      }

      // Check if selected only one date, automatically set the second date to the same value
      if (values.length == 1) {
        values.add(values[0]);
      }

      context.readFormContext().set(
            config.name,
            values,
          );
      context.readFormContext().rebuild();
      config.onChanged?.call(context, values);
    });
  }
}
