
import 'package:crud_o/resources/actions/crudo_action.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';


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
    return Container(
      width: 350,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme
                .of(context)
                .colorScheme
                .primary,
            width: 5,
          ),
        ),
        color: Colors.white,
      ),
      child: ListTile(
        dense: true,
        leading: icon,
        title: Text(name, style: const TextStyle(fontSize: 16)),
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
