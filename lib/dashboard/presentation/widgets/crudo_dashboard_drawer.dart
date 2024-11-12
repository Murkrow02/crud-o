import 'package:crud_o/auth/crudo_auth.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CrudoDashboardDrawer extends StatelessWidget {
  final Widget? afterAvatar;

  const CrudoDashboardDrawer({super.key, this.afterAvatar});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            _buildResourceTiles(context),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text('Logout',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                context.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTiles(BuildContext context) {
    // Get table and resources
    var tables = context.read<RegisteredResources>().tables;
    var resourcesWithTables = context
        .read<RegisteredResources>()
        .resources
        .where((e) => e.tablePage != null)
        .toList();

    // Group resources by group
    var groupedResources = <String, List<MapEntry<CrudoResource, Widget>>>{};

    // Create a list of futures for each resource's viewAny() check
    List<Future<void>> tasks = [];

    for (int i = 0; i < resourcesWithTables.length; i++) {
      var resource = resourcesWithTables[i];
      var table = tables[i];
      var group = resource.group();

      if (!groupedResources.containsKey(group)) {
        groupedResources[group] = [];
      }

      // If resource has a policy, we add its viewAny() check
      if (resource.policy != null) {
        tasks.add(resource.policy!.viewAny().then((canView) {
          if (canView) {
            groupedResources[group]!.add(MapEntry(resource, table));
          }
        }));
      } else {
        // If no policy, directly add the resource
        groupedResources[group]!.add(MapEntry(resource, table));
      }
    }

    // Return a FutureBuilder that awaits all tasks before rendering
    return FutureBuilder<void>(
      future: Future.wait(tasks),  // Wait for all async checks to complete
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());  // Show a loading indicator while waiting
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));  // Handle errors
        }

        if (!snapshot.hasData || groupedResources.isEmpty) {
          return const Center(child: Text('No resources available'));  // No resources found
        }

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
                          shape: Border(
                              bottom: BorderSide(
                                  color: Theme.of(context).dividerColor)),
                          initiallyExpanded: true,
                          title: Text(group),
                          children: [
                            for (var entry in groupedResources[group]!)
                              _buildResourceTile(context, entry.key, entry.value),
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
      },
    );
  }


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

  Widget _buildDrawerHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                height: 60,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                      'https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50'),
                ),
              ),
              const SizedBox(width: 10),
              Text('John Doe',
                  style: TextStyle(
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          if (afterAvatar != null) afterAvatar!,
        ],
      ),
    );
  }
}
