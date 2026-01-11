import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';

class CrudoGroupedResourcesView<T> extends StatelessWidget {
  final Future<Map<String, List<T>>> Function() futureBuilder;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// If true, groups with no visible children are hidden.
  final bool hideEmptyGroups;

  const CrudoGroupedResourcesView({
    super.key,
    required this.futureBuilder,
    required this.itemBuilder,
    this.hideEmptyGroups = true,
  });

  @override
  Widget build(BuildContext context) {
    return Futuristic<Map<String, List<T>>>(
      autoStart: true,
      futureBuilder: futureBuilder,
      errorBuilder: (context, error, retry) => Expanded(
        child: Center(child: Text('Error: $error')),
      ),
      busyBuilder: (context) => const Expanded(
        child: Center(child: CircularProgressIndicator()),
      ),
      dataBuilder: (context, grouped) {
        if (grouped == null) {
          return const Expanded(
            child: Center(child: Text('No resources available')),
          );
        }

        final groupKeys = grouped.keys.toList();

        return Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                for (final group in groupKeys)
                  _GroupSection<T>(
                    groupName: group,
                    items: grouped[group] ?? const [],
                    itemBuilder: itemBuilder,
                    hideIfEmpty: hideEmptyGroups,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GroupSection<T> extends StatelessWidget {
  final String groupName;
  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool hideIfEmpty;

  const _GroupSection({
    required this.groupName,
    required this.items,
    required this.itemBuilder,
    required this.hideIfEmpty,
  });

  @override
  Widget build(BuildContext context) {
    final themeConfig = CrudoConfiguration.theme();

    // Build children once and remove "invisible" placeholders
    final builtChildren = <Widget>[];
    for (final item in items) {
      final w = itemBuilder(context, item);
      if (_isEffectivelyEmpty(w)) continue;
      builtChildren.add(w);
    }

    if (hideIfEmpty && builtChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    // Default group: no ExpansionTile
    if (groupName.isEmpty) {
      return Column(children: builtChildren);
    }

    return Theme(
      // Make ExpansionTile feel less "default Material"
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: themeConfig.groupSectionTilePadding,
        childrenPadding: themeConfig.groupSectionChildrenPadding,
        title: Text(
          groupName,
          style: TextStyle(
            fontWeight: themeConfig.groupSectionTitleFontWeight,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(themeConfig.groupSectionTitleOpacity),
          ),
        ),
        children: [
          ...builtChildren,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  bool _isEffectivelyEmpty(Widget w) {
    // Common cases you return to "skip rendering"
    return w is SizedBox && (w.width == 0 || w.width == null) && (w.height == 0 || w.height == null) ||
        w is SizedBox && w.child == null;
  }
}