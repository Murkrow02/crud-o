import 'package:crud_o/auth/crudo_auth.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table_page.dart';
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
              title:  Text('Logout', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                context.logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTiles(BuildContext context){

    // Get table and resources
    var tables = context.read<RegisteredResources>().tables;
    var resources = context.read<RegisteredResources>().resources;

    // Group resources by group
    var groupedResources = <String, List<MapEntry<CrudoResource, CrudoTablePage>>>{};
    for (int i = 0; i < resources.length; i++) {
      var resource = resources[i];
      var table = tables[i];
      var group = resource.group();
      if (!groupedResources.containsKey(group)) {
        groupedResources[group] = [];
      }
      if(resource.showInDrawer)
      groupedResources[group]!.add(MapEntry(resource, table));
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
                      shape: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
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
  }


  Widget _buildResourceTile(BuildContext context, CrudoResource resource, CrudoTablePage table) {
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
                  backgroundImage: NetworkImage('https://www.gravatar.com/avatar/205e460b479e2e5b48aec07710c08d50'),
                ),
              ),
              const SizedBox(width: 10),
              Text('John Doe', style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.onSurface)),
            ],
          ),
          if (afterAvatar != null) afterAvatar!,
        ],
      ),
    );
  }
}
