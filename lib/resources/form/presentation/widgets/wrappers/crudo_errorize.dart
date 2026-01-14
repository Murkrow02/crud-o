import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/crudo_field_entry.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:flutter/material.dart';

/// A widget that displays validation errors below its child.
/// Shows error messages with consistent styling and smooth animations.
class CrudoErrorize extends StatelessWidget {
  final Widget child;
  final CrudoFieldConfiguration config;

  const CrudoErrorize({
    super.key,
    required this.child,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    var error = context.readFormContext().validationErrors[config.name]?.first;
    final hasError = error != null && error.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6.0, left: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          error!,
                          style: TextStyle(
                            color: colorScheme.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
