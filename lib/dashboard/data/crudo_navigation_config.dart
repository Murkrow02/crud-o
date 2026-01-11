import 'package:crud_o_core/auth/data/models/crudo_user.dart';
import 'package:flutter/material.dart';


class CrudoNavigationConfig {
  final Widget? afterAvatar;
  final Widget? beforeLogout;
  final Future<CrudoUser> Function()? getUserData;

  final List<CrudoExtraNavItem> extraItems;

  const CrudoNavigationConfig({
    this.afterAvatar,
    this.beforeLogout,
    this.getUserData,
    this.extraItems = const [],
  });
}

class CrudoExtraNavItem {
  final int navigationOrder;
  final IconData icon;
  final String title;
  final String routeName;

  /// Optional: navigate to a page inside the content navigator.
  final WidgetBuilder? pageBuilder;

  /// Optional: run a custom action.
  /// This will be invoked with a "safe" context under the content navigator.
  final Future<void> Function(BuildContext context)? onTap;

  /// Only relevant if pageBuilder != null.
  /// - false: push (keeps back stack)
  /// - true: replace (like sidebar), keeping Home as base
  final bool replace;

  /// Whether clicking on this item when already selected should replace
  /// the current page with a new instance.
  /// - true (default): re-clicking replaces the page
  /// - false: re-clicking does nothing
  final bool replaceOnReselect;

  const CrudoExtraNavItem({
    required this.navigationOrder,
    required this.icon,
    required this.title,
    required this.routeName,
    this.pageBuilder,
    this.onTap,
    this.replace = false,
    this.replaceOnReselect = true,
  }) : assert(
  pageBuilder != null || onTap != null,
  'CrudoExtraNavItem must provide either pageBuilder or onTap',
  );
}