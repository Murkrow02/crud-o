import 'package:crud_o/dashboard/presentation/widgets/crudo_nav_tile.dart';
import 'package:flutter/material.dart';

class CrudoHomeTile extends StatelessWidget {
  final String currentRoute;
  final VoidCallback onTap;
  const CrudoHomeTile({super.key, required this.currentRoute, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CrudoNavTile(
      selected: currentRoute == '/',
      icon: Icons.home_rounded,
      title: 'Dashboard',
      navigationOrder: -1000,
      dense: false,
      onTap: onTap,
    );
  }
}
