
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:crud_o_core/resources/actions/crudo_action.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:flutter/material.dart';


class CrudoDashboardShortcut extends StatelessWidget {
  final Widget icon;
  final String name;
  final VoidCallback onTap;

  const CrudoDashboardShortcut({
    super.key,
    required this.icon,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final themeConfig = CrudoConfiguration.theme();

    return Container(
      width: themeConfig.dashboardShortcutWidth,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: themeConfig.dashboardShortcutBorderColor ?? Theme.of(context).colorScheme.primary,
            width: themeConfig.dashboardShortcutBorderWidth,
          ),
        ),
        color: themeConfig.dashboardShortcutBackgroundColor,
      ),
      child: ListTile(
        dense: true,
        leading: icon,
        title: Text(name, style: TextStyle(fontSize: themeConfig.dashboardShortcutTitleFontSize)),
        onTap: onTap,
      ),
    );
  }
}


class CrudoResourceActionDashboardShortcut extends StatelessWidget {
  final CrudoResource resource;
  final CrudoAction action;

  const CrudoResourceActionDashboardShortcut({
    super.key,
    required this.resource,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return CrudoDashboardShortcut(
      icon: Icon(resource.icon()),
      name: '${action.label} ${resource.singularName()}',
      onTap: () {
        action.execute(context);
      },
    );
  }
}

class ResourceActionPair {
  CrudoResource resource;
  CrudoAction action;

  ResourceActionPair(this.resource, this.action);
}
