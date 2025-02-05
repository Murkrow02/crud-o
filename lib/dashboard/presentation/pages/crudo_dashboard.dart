import 'dart:typed_data';
import 'package:crud_o/auth/crudo_auth.dart';
import 'package:crud_o/auth/data/models/crudo_user.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';
import 'package:provider/provider.dart';

class CrudoDashboard extends StatelessWidget {
  final Widget child;
  final CrudoDashboardConfig? config;
  final PreferredSizeWidget? appBar;

  const CrudoDashboard(
      {super.key, this.config, required this.child, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: appBar,
      body: child,
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            _buildResourceTiles(context),
            const Divider(),
            _buildDrawerFooter(context),
          ],
        ),
      ),
    );
  }

  /// Header with user info, displayed at the top of the drawer
  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          if (config?.getUserData != null)
            Futuristic<CrudoUser>(
              autoStart: true,
              futureBuilder: config!.getUserData!,
              busyBuilder: (context) => const CircularProgressIndicator(),
              dataBuilder: (context, user) {
                if (user == null) return const SizedBox();
                return Row(
                  children: [
                    SizedBox(
                      height: 50,
                      child: Futuristic<Uint8List>(
                        autoStart: true,
                        futureBuilder: user.getAvatar,
                        dataBuilder: (context, data) {
                          if (data == null) return const SizedBox();
                          return CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            radius: 30,
                            backgroundImage: MemoryImage(data),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(user.getName(),
                        style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onSurface)),
                  ],
                );
              },
            ),
          if (config?.afterAvatar != null) config!.afterAvatar!,
        ],
      ),
    );
  }

  /// Single tile for a resource
  Widget _buildResourceTile(
      BuildContext context, CrudoResource resource, Widget table) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ListTile(
        title: Row(
          children: [
            Icon(resource.icon()),
            const SizedBox(width: 10),
            Text(resource.pluralName()),
          ],
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => table,
          ));
        },
      ),
    );
  }

  /// List of tiles for all resources
  Widget _buildResourceTiles(BuildContext context) {
    return Futuristic<Map<String, List<MapEntry<CrudoResource, Widget>>>>(
        autoStart: true,
        futureBuilder: () => _getAvailableResources(context),
        errorBuilder: (context, error, retry) =>
            Text('Error: ${error.toString()}'),
        busyBuilder: (context) =>
            Expanded(child: const Center(child: CircularProgressIndicator())),
        dataBuilder: (context, groupedResources) {
          if (groupedResources == null)
            return const Text('No resources available');
          return Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var group in groupedResources.keys)
                    Column(
                      children: [
                        // If group is not empty, show expansion tile
                        if (group != '')
                          ExpansionTile(
                            initiallyExpanded: false,
                            title: Text(group),
                            children: [
                              for (var entry in groupedResources[group]!)
                                _buildResourceTile(
                                    context, entry.key, entry.value),
                              const SizedBox(height: 15),
                            ],
                          ),

                        // Default group, just show tiles
                        if (group == '')
                          for (var entry in groupedResources[group]!)
                            _buildResourceTile(context, entry.key, entry.value),
                      ],
                    ),
                ],
              ),
            ),
          );
        });
  }

  /// Footer with logout options, displayed at the bottom of the drawer
  Widget _buildDrawerFooter(BuildContext context) {
    return Column(
      children: [
        if (config?.beforeLogout != null) config!.beforeLogout!,
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text('Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          onTap: () {
            context.logout();
          },
        ),
      ],
    );
  }

  /// This is the trickiest part of the widget
  /// It groups resources by group, and checks if the user can view each resource using the policy viewAny() method
  /// If the resource has a policy, it will only be shown if the user can view it
  Future<Map<String, List<MapEntry<CrudoResource, Widget>>>>
      _getAvailableResources(BuildContext context) async {

    // Get table and resources
    var tables = context.read<RegisteredResources>().tables;
    var resourcesWithTables = context
        .read<RegisteredResources>()
        .resources
        .where((e) => e.tablePage != null)
        .toList();

    // Group resources by group
    var groupedResources = <String, List<MapEntry<CrudoResource, Widget>>>{};

    // Cycle on each resource
    for (int i = 0; i < resourcesWithTables.length; i++) {
      var resource = resourcesWithTables[i];
      var table = tables[i];
      var group = resource.group();

      if (!groupedResources.containsKey(group)) {
        groupedResources[group] = [];
      }

      // If resource has a policy, we add its viewAny() check
      if (resource.policy != null) {
        var canView = await resource.policy!.viewAny();
        if (canView) {
          groupedResources[group]!.add(MapEntry(resource, table));
        }
      } else {
        // If no policy, directly add the resource
        groupedResources[group]!.add(MapEntry(resource, table));
      }
    }

    // Sort groups alphabetically
    groupedResources = Map.fromEntries(groupedResources.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));

    // Sort each resource inside group based on navigationSort
    groupedResources.forEach((key, value) {
      value.sort((a, b) => a.key.navigationSort().compareTo(b.key.navigationSort()));
    });

    return groupedResources;
  }
}

class CrudoDashboardConfig {
  final Widget? afterAvatar;
  final Widget? beforeLogout;
  final Future<CrudoUser> Function()? getUserData;

  CrudoDashboardConfig(
      {this.afterAvatar, this.beforeLogout, this.getUserData});
}
