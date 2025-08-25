import 'package:crud_o/dashboard/presentation/widgets/crudo_dashboard_shortcut.dart';
import 'package:crud_o_core/resources/actions/crudo_action.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o_core/resources/resource_provider.dart';
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

  const CrudoDashboardShortcuts({
    super.key,
    this.alwaysPresentShortcuts,
    this.defaultShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return Futuristic<List<Widget>>(
      autoStart: true,
      futureBuilder: () => _getUserSelectedShortcuts(context),
      busyBuilder: (context) => const CircularProgressIndicator(),
      dataBuilder: (context, resourceActions) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutsHeader(context),
            const SizedBox(height: 16),
            _buildShortcutsWrap(context, resourceActions!),
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
        Text(
          'Azioni rapide',
          style: TextStyle(
            fontSize: 20,
            color: Theme
                .of(context)
                .colorScheme
                .primary,
          ),
        ),
        // IconButton(
        //   icon: const Icon(Icons.edit),
        //   onPressed: () async {
        //     var shortcutsActionDialog = await _buildShortcutsEditDialog(
        //         context);
        //     return showDialog(
        //       context: context,
        //       builder: (context) => shortcutsActionDialog,
        //     );
        //   },
        // ),
      ],
    );
  }

  /// Uses Wrap instead of GridView to display shortcuts without scroll
  Widget _buildShortcutsWrap(BuildContext context,
      List<Widget> userSelectedShortcuts) {
    final shortcuts = [
      ...?alwaysPresentShortcuts,
      ...userSelectedShortcuts,
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: shortcuts,
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
      title: const Text('Modifica azioni rapide WIP'),
      content: SingleChildScrollView(
        child: Column(
          children: resourceWidgets,
        ),
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
