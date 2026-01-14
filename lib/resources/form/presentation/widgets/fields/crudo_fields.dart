library crudo_fields;

import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

export 'crudo_datetime_field.dart';
export 'crudo_dropdown_field.dart';
export 'crudo_future_dropdown_field.dart';
export 'crudo_table_field.dart';
export 'crudo_text_field.dart';
export 'crudo_repeater_field.dart';

/// Creates the default InputDecoration for form fields using theme configuration.
/// This ensures consistent styling across all form fields.
InputDecoration defaultDecoration(BuildContext context) {
  final theme = CrudoConfiguration.theme();
  final colorScheme = Theme.of(context).colorScheme;

  final borderRadius = BorderRadius.circular(theme.fieldBorderRadius);
  final fillColor = theme.fieldFillColor ?? colorScheme.surface;
  final borderColor = theme.fieldBorderColor ?? colorScheme.outline.withOpacity(0.3);
  final focusedBorderColor = theme.fieldFocusedBorderColor ?? colorScheme.primary.withOpacity(0.6);
  final errorBorderColor = theme.fieldErrorBorderColor ?? colorScheme.error;

  return InputDecoration(
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: theme.fieldLabelStyle ?? TextStyle(
      color: colorScheme.onSurface.withOpacity(0.6),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: fillColor,
    hintStyle: theme.fieldHintStyle ?? TextStyle(
      color: colorScheme.onSurface.withOpacity(0.35),
      fontWeight: FontWeight.w400,
    ),
    contentPadding: theme.fieldContentPadding,
    border: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        width: theme.fieldBorderWidth,
        color: borderColor,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        width: theme.fieldFocusedBorderWidth,
        color: focusedBorderColor,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        width: theme.fieldBorderWidth,
        color: errorBorderColor,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        width: theme.fieldFocusedBorderWidth,
        color: errorBorderColor,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(
        width: theme.fieldBorderWidth,
        color: borderColor.withOpacity(0.5),
      ),
    ),
  );
}
