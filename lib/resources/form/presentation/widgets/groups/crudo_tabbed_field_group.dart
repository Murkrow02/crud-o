import 'package:crud_o_core/configuration/crudo_theme_config.dart';
import 'package:custom_sliding_segmented_control/custom_sliding_segmented_control.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

/// A tabbed container for grouping form fields with modern sliding segment styling.
/// Uses theme configuration for consistent styling.
class CrudoTabbedFieldGroup extends StatefulWidget {
  final List<CrudoTabbedField> tabs;
  final int initialIndex;
  final EdgeInsets? padding;

  const CrudoTabbedFieldGroup({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.padding,
  });

  @override
  State<CrudoTabbedFieldGroup> createState() => _CrudoTabbedFieldGroupState();
}

class _CrudoTabbedFieldGroupState extends State<CrudoTabbedFieldGroup> {
  late int activeTabIndex;

  @override
  void initState() {
    super.initState();
    activeTabIndex = widget.initialIndex;
  }

  Map<int, Widget> getTabsHeaders(CrudoThemeConfig theme, ColorScheme colorScheme) {
    return {
      for (var i = 0; i < widget.tabs.length; i++)
        i: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tabs[i].icon != null) ...[
                Icon(
                  widget.tabs[i].icon,
                  size: 18,
                  color: activeTabIndex == i
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.tabs[i].label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: activeTabIndex == i
                      ? FontWeight.w600
                      : FontWeight.w500,
                  color: activeTabIndex == i
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        )
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    final backgroundColor = theme.tabbedGroupBackgroundColor ??
        colorScheme.surfaceContainerHighest.withOpacity(0.5);
    final thumbColor = theme.tabbedGroupThumbColor ?? colorScheme.surface;

    assert(widget.tabs.isNotEmpty, 'Please provide at least one tab');

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(theme.tabbedGroupBorderRadius),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: CustomSlidingSegmentedControl<int>(
              initialValue: activeTabIndex,
              children: getTabsHeaders(theme, colorScheme),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(theme.tabbedGroupBorderRadius),
              ),
              thumbDecoration: BoxDecoration(
                color: thumbColor,
                borderRadius: BorderRadius.circular(theme.tabbedGroupBorderRadius - 2),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              duration: theme.tabbedGroupAnimationDuration,
              curve: Curves.easeInOut,
              onValueChanged: (index) {
                setState(() {
                  activeTabIndex = index;
                });
                widget.tabs[index].onSelected?.call();
              },
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            child: IndexedStack(
              key: ValueKey<int>(activeTabIndex),
              index: activeTabIndex,
              children: widget.tabs.map((tab) => tab.child).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents a single tab in a CrudoTabbedFieldGroup.
class CrudoTabbedField {
  final String label;
  final Widget child;
  final IconData? icon;
  final VoidCallback? onSelected;

  CrudoTabbedField({
    required this.label,
    required this.child,
    this.icon,
    this.onSelected,
  });
}
