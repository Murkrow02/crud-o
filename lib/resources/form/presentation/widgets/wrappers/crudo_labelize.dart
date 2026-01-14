import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

/// A widget that adds a floating label above its child.
/// Uses theme configuration for consistent label styling.
class CrudoLabelize extends StatelessWidget {
  final String label;
  final Widget child;
  final double offset;
  final bool isRequired;

  const CrudoLabelize({
    super.key,
    required this.label,
    required this.child,
    this.offset = 10,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    final labelColor = colorScheme.onSurface.withOpacity(0.55);
    final backgroundColor = theme.fieldFillColor ?? colorScheme.surface;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -offset,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.fieldLabelStyle ?? TextStyle(
                    color: labelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.15,
                  ),
                ),
                if (isRequired) ...[
                  const SizedBox(width: 2),
                  Text(
                    '*',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}