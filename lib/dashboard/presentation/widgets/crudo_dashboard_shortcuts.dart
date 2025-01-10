import 'package:crud_o/resources/actions/crudo_action.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futuristic/futuristic.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrudoDashboardShortcuts extends StatelessWidget {
  /// Shortcuts that are always present in the shortcuts section and cannot be removed
  final List<CrudoDashboardShortcut>? alwaysPresentShortcuts;

  /// Shortcuts that are visible by default if no custom shortcuts are selected by the user
  /// The String key is the name of the shortcut and the Widget is the widget to be displayed
  /// The key is used to identify the shortcut in the preferences
  final Map<String, Widget>? defaultShortcuts;

  const CrudoDashboardShortcuts(
      {super.key, this.alwaysPresentShortcuts, this.defaultShortcuts});

  @override
  Widget build(BuildContext context) {
    return Futuristic<List<Widget>>(
      autoStart: true,
      futureBuilder: () => _getUserSelectedShortcuts(context),
      busyBuilder: (context) => const CircularProgressIndicator(),
      dataBuilder: (context, resourceActions) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildShortcutsHeader(context),
            _buildShortcutsGrid(context, resourceActions!),
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
        IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              var shortcutsActionDialog =
                  await _buildShortcutsEditDialog(context);
              return showDialog(
                  context: context,
                  builder: (context) => shortcutsActionDialog);
            })
      ],
    );
  }

  /// The actual grid where shortcuts are displayed
  Widget _buildShortcutsGrid(
      BuildContext context, List<Widget> userSelectedShortcuts) {
    // Calculate the number of columns based on screen width and item width
    final screenWidth = MediaQuery.of(context).size.width;
    const itemWidth = 350;
    final crossAxisCount = (screenWidth / itemWidth).floor();

    // Combine additionalShortcuts and userSelectedShortcuts into a new list
    final shortcuts = [
      ...?alwaysPresentShortcuts,
      ...userSelectedShortcuts,
    ];

    return Expanded(
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 6,
        children: shortcuts,
      ),
    );
  }

  /// Get all available actions for all resources
  Future<List<Widget>> _getUserSelectedShortcuts(BuildContext context) async {
    var prefs = await SharedPreferences.getInstance();

    // Get selected shortcuts from preferences
    List<String> selectedShortcuts =
        prefs.getStringList('crudo_selected_shortcuts') ?? [];

    return List.from(defaultShortcuts?.values ?? []);
  }

  Future<Widget> _buildShortcutsEditDialog(BuildContext context) async {
    var actions = await _getAllAvailableResourceActions(context);
    var resourceWidgets = actions.map((resourceActionPair) {
      return CrudoResourceActionDashboardShortcut(
        resource: resourceActionPair.resource,
        action: resourceActionPair.action,
      ) as Widget;
    }).toList();

    return AlertDialog(
      title: const Text('Seleziona azioni rapide WIP'),
      content: SingleChildScrollView(
        child: Column(children: resourceWidgets),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Chiudi'),
        ),
      ],
    );
  }

  Future<List<ResourceActionPair>> _getAllAvailableResourceActions(
      BuildContext context) async {
    // Get all registeredResources
    var registeredResources = context.read<RegisteredResources>();
    var resources = registeredResources.resources;
    var actions = <ResourceActionPair>[];

    // Get actions for each resource
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
  final CrudoResource resource;
  final CrudoAction action;

  const CrudoResourceActionDashboardShortcut(
      {super.key, required this.resource, required this.action});

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
