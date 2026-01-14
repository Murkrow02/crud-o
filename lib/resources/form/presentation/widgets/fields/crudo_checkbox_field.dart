import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

/// A styled checkbox field with modern design.
/// Uses theme configuration for consistent styling.
class CrudoCheckboxField extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final bool useSwitch;

  const CrudoCheckboxField({
    super.key,
    required this.config,
    this.useSwitch = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    final activeColor = theme.checkboxActiveColor ?? colorScheme.primary;
    final checkColor = theme.checkboxCheckColor ?? colorScheme.onPrimary;
    final fillColor = theme.fieldFillColor ?? colorScheme.surface;
    final borderColor = theme.fieldBorderColor ?? colorScheme.outline.withOpacity(0.3);

    return CrudoField(
      viewModeValue: context.readFormContext().get(config.name) == true
          ? "Yes"
          : "No",
      config: config,
      editModeBuilder: (context, onChanged) {
        final isChecked = context.readFormContext().get(config.name) == true;
        final isEnabled = config.shouldEnableField(context);

        return Container(
          height: theme.checkboxFieldHeight,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(theme.checkboxFieldBorderRadius),
            border: Border.all(
              color: borderColor,
              width: theme.fieldBorderWidth,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(theme.checkboxFieldBorderRadius),
              onTap: isEnabled
                  ? () {
                      onChanged(context, !isChecked);
                      context.readFormContext().rebuild();
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    if (useSwitch)
                      Switch.adaptive(
                        value: isChecked,
                        onChanged: isEnabled
                            ? (value) {
                                onChanged(context, value);
                                context.readFormContext().rebuild();
                              }
                            : null,
                        thumbColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return activeColor;
                          }
                          return null;
                        }),
                        trackColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return activeColor.withAlpha(100);
                          }
                          return null;
                        }),
                      )
                    else
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isChecked ? activeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(theme.checkboxBorderRadius),
                          border: Border.all(
                            color: isChecked
                                ? activeColor
                                : colorScheme.outline.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: isChecked
                            ? Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: checkColor,
                              )
                            : null,
                      ),
                    if (config.placeholder != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          config.placeholder!,
                          style: TextStyle(
                            fontSize: 15,
                            color: isEnabled
                                ? colorScheme.onSurface
                                : colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
