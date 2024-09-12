import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_dashboard_widget.dart';
import 'package:crud_o/resources/resource_provider.dart';
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
      child: ListView(
        padding: EdgeInsets.zero,
        children: List.generate(
          tables.length,
              (index) => ListTile(
            title: Text(resources[index].pluralName()),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => tables[index]));
            },
          ),
        ),
      ),
    );
  }
}