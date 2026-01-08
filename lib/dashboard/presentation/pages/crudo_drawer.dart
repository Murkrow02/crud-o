import 'package:crud_o/dashboard/data/crudo_navigation_config.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_grouped_resources_view.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_home_tile.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_nav_footer.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_nav_header.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_nav_tile.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o_core/resources/resource_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrudoDrawer extends StatefulWidget {
  final Widget home;
  final CrudoNavigationConfig? config;

  const CrudoDrawer({
    super.key,
    required this.home,
    this.config,
  });

  @override
  State<CrudoDrawer> createState() => _CrudoDrawerState();
}

class _CrudoDrawerState extends State<CrudoDrawer> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<NavigatorState> _contentNavKey = GlobalKey<NavigatorState>();

  String _currentRoute = '/';

  // --- ROUTE NAV (resources + home) ---
  void _go(String routeName) {
    if (_currentRoute == routeName) return;

    setState(() => _currentRoute = routeName);

    // close drawer
    Navigator.of(context).pop();

    final nav = _contentNavKey.currentState!;

    if (routeName == '/') {
      nav.pushNamedAndRemoveUntil('/', (r) => false);
      return;
    }

    // Keep HOME as root => back always returns to home
    nav.pushNamedAndRemoveUntil(
      routeName,
          (r) => r.settings.name == '/',
    );
  }

  // --- EXTRA NAV (custom pages) ---
  Future<void> _openExtra(CrudoExtraNavItem item) async {
    // close drawer
    Navigator.of(context).pop();

    final nav = _contentNavKey.currentState!;
    final safeCtx = _contentNavKey.currentContext ?? context;

    // ACTION mode
    if (item.onTap != null) {
      await item.onTap!(safeCtx);
      return;
    }

    // NAVIGATION mode (pageBuilder is guaranteed by assert)
    final builder = item.pageBuilder!;
    if (item.replace) {
      nav.pushAndRemoveUntil(
        MaterialPageRoute(builder: builder),
            (r) => r.settings.name == '/',
      );
    } else {
      nav.push(MaterialPageRoute(builder: builder));
    }
  }

  String _routeNameOfResource(BuildContext context, CrudoResource resource) {
    final registered = context.read<RegisteredResources>();
    final idx = registered.resources.indexOf(resource);
    return '/r/$idx';
  }

  Future<bool> _onWillPop() async {
    final nav = _contentNavKey.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }
    return true;
  }

  PreferredSizeWidget _buildHomeAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: const Text(''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: [
                CrudoNavHeader(
                  config: widget.config,
                  avatarRadius: 30,
                  fontSize: 20,
                ),

                CrudoHomeTile(
                  currentRoute: _currentRoute,
                  onTap: () => _go('/'),
                ),

                CrudoGroupedResourcesView<_NavEntry>(
                  futureBuilder: () => _getAvailableEntries(context),
                  itemBuilder: (context, entry) {
                    // EXTRA ITEM
                    if (entry.extra != null) {
                      final e = entry.extra!;
                      return CrudoNavTile(
                        selected: false,
                        icon: e.icon,
                        title: e.title,
                        navigationOrder: e.navigationOrder,
                        dense: false,
                        height: 50,
                        iconSize: 24,
                        onTap: () => _openExtra(e),
                      );
                    }

                    // RESOURCE
                    final resource = entry.resource!;
                    final route = _routeNameOfResource(context, resource);

                    return CrudoNavTile(
                      selected: false,
                      icon: resource.icon(),
                      title: resource.pluralName(),
                      navigationOrder: entry.order,
                      dense: false,
                      height: 50,
                      iconSize: 24,
                      onTap: () => _go(route),
                    );
                  },
                ),

                const Divider(),
                CrudoNavFooter(config: widget.config),
              ],
            ),
          ),
        ),
        body: Navigator(
          key: _contentNavKey,
          initialRoute: '/',
          onGenerateRoute: (settings) {
            final name = settings.name ?? '/';

            if (name == '/') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => Scaffold(
                  appBar: _buildHomeAppBar(context),
                  body: widget.home,
                ),
              );
            }

            final match = RegExp(r'^/r/(\d+)$').firstMatch(name);
            if (match != null) {
              final index = int.parse(match.group(1)!);
              final registered = context.read<RegisteredResources>();

              if (index >= 0 && index < registered.tables.length) {
                final tablePage = registered.tables[index];
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => tablePage,
                );
              }
            }

            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const Scaffold(
                body: Center(child: Text('Page not found')),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, List<_NavEntry>>> _getAvailableEntries(
      BuildContext context) async {
    final registered = context.read<RegisteredResources>();
    final resourcesWithTables =
    registered.resources.where((e) => e.tablePage != null).toList();

    final grouped = <String, List<_NavEntry>>{};

    // EXTRA ITEMS in default group
    final extras = widget.config?.extraItems ?? const <CrudoExtraNavItem>[];
    if (extras.isNotEmpty) {
      grouped.putIfAbsent('', () => []);
      for (final e in extras) {
        grouped['']!.add(_NavEntry.extra(e, order: e.navigationOrder));
      }
    }

    // RESOURCES
    for (final resource in resourcesWithTables) {
      final group = resource.group();
      grouped.putIfAbsent(group, () => []);

      if (resource.policy != null) {
        final canView = await resource.policy!.viewAny();
        if (!canView) continue;
      }

      grouped[group]!.add(
        _NavEntry.resource(resource, order: resource.navigationSort()),
      );
    }

    // Sort groups: '' first then alphabetically
    final keys = grouped.keys.toList();
    keys.sort((a, b) {
      if (a.isEmpty && b.isNotEmpty) return -1;
      if (b.isEmpty && a.isNotEmpty) return 1;
      return a.compareTo(b);
    });

    final sortedGrouped = <String, List<_NavEntry>>{};
    for (final k in keys) {
      final list = grouped[k]!;
      list.sort((a, b) => a.order.compareTo(b.order));
      sortedGrouped[k] = list;
    }

    return sortedGrouped;
  }
}

class _NavEntry {
  final int order;
  final CrudoResource? resource;
  final CrudoExtraNavItem? extra;

  const _NavEntry.resource(this.resource, {required this.order}) : extra = null;
  const _NavEntry.extra(this.extra, {required this.order}) : resource = null;
}