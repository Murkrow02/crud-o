import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_fields.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:datetime_picker_formfield_new/datetime_picker_formfield.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A styled datetime picker field with modern design.
/// Supports date-only, time-only, or combined datetime selection.
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
    final colorScheme = Theme.of(context).colorScheme;

    return CrudoField(
      config: config,
      viewModeValue: _formatDateTime(context.readFormContext().get(config.name) as DateTime?),
      editModeBuilder: (context, onChanged) => DateTimeField(
        decoration: defaultDecoration(context).copyWith(
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Icon(
              _getIcon(),
              size: 20,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: config.placeholder ?? _getPlaceholder(),
          suffixIcon: context.readFormContext().get(config.name) != null
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  onPressed: () {
                    onChanged(context, null);
                    context.readFormContext().rebuild();
                  },
                )
              : null,
        ),
        enabled: config.shouldEnableField(context),
        onChanged: (DateTime? value) => onChanged(context, value),
        initialValue: context.readFormContext().get(config.name) as DateTime?,
        format: format ?? getDefaultFormat(),
        onShowPicker: (BuildContext context, DateTime? currentValue) {
          return _showPicker(context, currentValue);
        },
      ),
    );
  }

  IconData _getIcon() {
    switch (inputType) {
      case DateTimePickerType.date:
        return Icons.calendar_today_rounded;
      case DateTimePickerType.time:
        return Icons.access_time_rounded;
      case DateTimePickerType.datetime:
        return Icons.event_rounded;
    }
  }

  String _getPlaceholder() {
    switch (inputType) {
      case DateTimePickerType.date:
        return 'Select date';
      case DateTimePickerType.time:
        return 'Select time';
      case DateTimePickerType.datetime:
        return 'Select date and time';
    }
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    return (format ?? getDefaultFormat()).format(dateTime);
  }

  Future<DateTime?> _showPicker(BuildContext context, DateTime? currentValue) async {
    final colorScheme = Theme.of(context).colorScheme;

    if (inputType == DateTimePickerType.time) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: colorScheme,
            ),
            child: child!,
          );
        },
      );
      if (time != null) {
        return DateTimeField.combine(DateTime.now(), time);
      }
      return currentValue;
    }

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      initialDate: currentValue ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 100)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (date == null) return currentValue;

    if (inputType == DateTimePickerType.date) {
      return date;
    }

    // For datetime type, also show time picker
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentValue ?? DateTime.now()),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme,
          ),
          child: child!,
        );
      },
    );

    return DateTimeField.combine(date, time);
  }

  DateFormat getDefaultFormat() {
    switch (inputType) {
      case DateTimePickerType.date:
        return DateFormat('dd MMM yyyy');
      case DateTimePickerType.time:
        return DateFormat('HH:mm');
      case DateTimePickerType.datetime:
        return DateFormat('dd MMM yyyy HH:mm');
    }
  }
}

enum DateTimePickerType { date, time, datetime }
