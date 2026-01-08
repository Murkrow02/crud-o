import 'package:crud_o/dashboard/data/crudo_navigation_config.dart';
import 'package:crud_o_core/auth/crudo_auth.dart';
import 'package:flutter/material.dart';

class CrudoNavFooter extends StatelessWidget {
  final CrudoNavigationConfig? config;

  const CrudoNavFooter({
    super.key,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = config;

    return Column(
      children: [
        if (cfg?.beforeLogout != null) cfg!.beforeLogout!,
        ListTile(
          dense: true,
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text(
            'Logout',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: () {
            context.logout();
          },
        ),
      ],
    );
  }
}