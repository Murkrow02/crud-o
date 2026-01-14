import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_errorize.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_labelize.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

/// A styled wrapper container for form fields.
/// Provides consistent padding, background, and border styling using theme configuration.
class CrudoFieldWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? customPadding;
  final Color? customBackgroundColor;

  const CrudoFieldWrapper({
    super.key,
    required this.child,
    this.customPadding,
    this.customBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = customBackgroundColor ??
        theme.fieldFillColor ??
        colorScheme.surface;
    final borderColor = theme.fieldBorderColor ??
        colorScheme.outline.withOpacity(0.3);

    return Container(
      padding: customPadding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(theme.fieldBorderRadius),
        border: Border.all(
          color: borderColor,
          width: theme.fieldBorderWidth,
        ),
      ),
      child: child,
    );
  }
}
