import 'package:crud_o/resources/actions/crudo_action.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futuristic/futuristic.dart';

class CrudoDashboardShortcuts extends StatelessWidget {
  final List<CrudoDashboardShortcut>? additionalActions;

  const CrudoDashboardShortcuts({super.key, this.additionalActions});

  @override
  Widget build(BuildContext context) {
    return Futuristic<List<ResourceActionPair>>(
      autoStart: true,
      futureBuilder: () => _getShortcutActions(context),
      busyBuilder: (context) => const CircularProgressIndicator(),
      dataBuilder: (context, actions) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShortcutsHeader(context),
            Expanded(child: _buildShortcutsGrid(context, actions!)),
          ],
        );
      },
    );
  }

  /// Builds the header of the shortcuts section with the edit icon to edit the shortcuts
  Widget _buildShortcutsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Azioni rapide',
            style: TextStyle(
                fontSize: 20, color: Theme.of(context).colorScheme.primary)),
        IconButton(icon: Icon(Icons.edit), onPressed: () {})
      ],
    );
  }

  /// The actual grid where shortcuts are displayed
  Widget _buildShortcutsGrid(
      BuildContext context, List<ResourceActionPair> shortcutActions) {
    return GridView.count(
      crossAxisCount: 3,
      childAspectRatio: 10,
      children: List.generate(shortcutActions.length, (index) {
        return CrudoResourceActionDashboardShortcut(
          resourceIcon: shortcutActions[index].resource.icon(),
          actionIcon: shortcutActions[index].action.icon ?? Icons.add,
          title:
              '${shortcutActions[index].action.label} ${shortcutActions[index].resource.singularName()}',
          onTap: () {
            shortcutActions[index].action.execute(context);
          },
        );
      })
        ..insertAll(0,additionalActions ?? []),
    );
  }

  /// Get all available actions for all resources
  Future<List<ResourceActionPair>> _getShortcutActions(
      BuildContext context) async {
    // Get all registeredResources
    var registeredResources = context.read<RegisteredResources>();
    var resources = registeredResources.resources;
    var actions = <ResourceActionPair>[];
    for (var resource in resources) {
      var resourceActions = await resource.availableResourceActions();
      for (var action in resourceActions) {
        actions.add(ResourceActionPair(resource, action));
      }
    }
    return actions;
  }
}

class CrudoDashboardShortcut extends StatelessWidget {
  final Widget icon;
  final String name;
  final VoidCallback onTap;

  const CrudoDashboardShortcut(
      {super.key, required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListTile(
        leading: icon,
        title: Text(name),
        onTap: onTap,
      ),
    );
  }
}

class CrudoResourceActionDashboardShortcut extends StatelessWidget {
  final IconData resourceIcon;
  final IconData? actionIcon;
  final String title;
  final VoidCallback onTap;

  const CrudoResourceActionDashboardShortcut(
      {super.key,
      required this.resourceIcon,
      this.actionIcon,
      required this.title,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CrudoDashboardShortcut(
      icon: Icon(resourceIcon),
      // icon: Row(
      //   children: [
      //     Icon(resourceIcon),
      //     if (actionIcon != null) Padding(
      //       padding: const EdgeInsets.only(left: 4),
      //       child: Icon(actionIcon),
      //     )
      //   ],
      // ),
      name: title,
      onTap: onTap,
    );
  }
}

class ResourceActionPair {
  CrudoResource resource;
  CrudoAction action;

  ResourceActionPair(this.resource, this.action);
}
