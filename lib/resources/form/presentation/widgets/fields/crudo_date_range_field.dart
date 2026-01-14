import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A styled date range picker field with modern design.
/// Uses theme configuration for consistent styling.
class CrudoDateRangeField extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final DateFormat? format;
  final CalendarDatePicker2Type calendarType;
  final String placeholder;

  const CrudoDateRangeField({
    super.key,
    required this.config,
    this.format,
    this.calendarType = CalendarDatePicker2Type.range,
    this.placeholder = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    final fillColor = theme.fieldFillColor ?? colorScheme.surface;
    final borderColor = theme.fieldBorderColor ?? colorScheme.outline.withOpacity(0.3);

    return CrudoField(
      config: config,
      editModeBuilder: (context, onChanged) {
        final dateRange = context.readFormContext().get(config.name) as List<DateTime?>?;
        final hasValue = dateRange != null && dateRange.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: config.shouldEnableField(context)
                ? () => _openDatePicker(context)
                : null,
            borderRadius: BorderRadius.circular(theme.fieldBorderRadius),
            child: Container(
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: BorderRadius.circular(theme.fieldBorderRadius),
                border: Border.all(
                  color: borderColor,
                  width: theme.fieldBorderWidth,
                ),
              ),
              padding: theme.fieldContentPadding,
              child: Row(
                children: [
                  Icon(
                    Icons.date_range_rounded,
                    size: 20,
                    color: hasValue
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasValue
                          ? _formatDateRange(dateRange)
                          : placeholder,
                      style: TextStyle(
                        fontSize: 15,
                        color: hasValue
                            ? colorScheme.onSurface
                            : colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                  if (hasValue)
                    GestureDetector(
                      onTap: () {
                        context.readFormContext().set(config.name, null);
                        context.readFormContext().rebuild();
                      },
                      child: Icon(
                        Icons.clear_rounded,
                        size: 20,
                        color: colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDateRange(List<DateTime?> dateRange) {
    final dateFormat = format ?? DateFormat('dd MMM yyyy');
    final start = dateRange[0];
    final end = dateRange.length > 1 ? dateRange[1] : null;

    if (start == null) return '';
    if (end == null) return dateFormat.format(start);

    return '${dateFormat.format(start)} — ${dateFormat.format(end)}';
  }

  void _openDatePicker(BuildContext context) async {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: calendarType,
        selectedDayHighlightColor: colorScheme.primary,
        selectedDayTextStyle: TextStyle(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        todayTextStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        dayTextStyle: TextStyle(
          color: colorScheme.onSurface,
        ),
        weekdayLabelTextStyle: TextStyle(
          color: colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w600,
        ),
        controlsTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogSize: const Size(340, 420),
      borderRadius: BorderRadius.circular(theme.dateRangeDialogBorderRadius),
    ).then((List<DateTime?>? values) {
      if (values == null || values.isEmpty) {
        return;
      }

      // Auto-set second date if only one selected
      if (values.length == 1) {
        values.add(values[0]);
      }

      context.readFormContext().set(config.name, values);
      context.readFormContext().rebuild();
      config.onChanged?.call(context, values);
    });
  }
}
