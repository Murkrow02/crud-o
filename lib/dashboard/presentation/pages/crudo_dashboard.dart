import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/auth/crudo_auth.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_dashboard_widget.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrudoDashboard extends StatelessWidget {
  const CrudoDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const Center(
        child: Wrap(
          spacing: 0,
          children: [
            CrudoDashboardWidget.half(),
            CrudoDashboardWidget.half(),
            CrudoDashboardWidget.full(),
            CrudoDashboardWidget.full(),
            CrudoDashboardWidget.third(),
            CrudoDashboardWidget.third(),
            CrudoDashboardWidget.third(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    var tables = context.read<RegisteredResources>().tables;
    var resources = context.read<RegisteredResources>().resources;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (int i = 0; i < tables.length; i++)
                      _buildResourceTile(context, resources[i], tables[i]),
                  ],
                ),
              ),
            ),
            ListTile(
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
    return const DrawerHeader(
      child: Column(
        children: [
          Text('Warehouse Manager'),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}