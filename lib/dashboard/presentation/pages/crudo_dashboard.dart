import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/auth/crudo_auth.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_dashboard_drawer.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_dashboard_widget.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrudoDashboard extends StatelessWidget {

  final Widget? afterAvatar;
  final Widget child;
  const CrudoDashboard({super.key, this.afterAvatar, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CrudoDashboardDrawer(afterAvatar: afterAvatar),
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: child,
    );
  }
}