import 'package:crud_o/dashboard/presentation/widgets/crudo_nav_tile.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

class CrudoHomeTile extends StatelessWidget {
  final String currentRoute;
  final VoidCallback onTap;
  const CrudoHomeTile({super.key, required this.currentRoute, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final themeConfig = CrudoConfiguration.theme();
    return CrudoNavTile(
      selected: currentRoute == '/',
      icon: themeConfig.homeTileIcon,
      title: themeConfig.homeTileTitle,
      navigationOrder: -1000,
      dense: false,
      onTap: onTap,
    );
  }
}
