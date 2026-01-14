import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

/// A styled container for displaying read-only field values.
/// Uses theme configuration for consistent styling across the application.
class CrudoViewField extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final Widget child;

  const CrudoViewField({
    super.key,
    required this.config,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = theme.viewFieldBackgroundColor ?? colorScheme.surface;
    final borderColor = theme.viewFieldBorderColor ?? colorScheme.outline.withOpacity(0.15);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(theme.viewFieldBorderRadius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      width: double.infinity,
      child: Padding(
        padding: theme.viewFieldPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              config.label ?? config.name,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontWeight: theme.viewFieldTitleFontWeight,
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: theme.viewFieldTitleFontSize,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 15,
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w400,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
