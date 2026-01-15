import 'package:crud_o/dashboard/data/crudo_navigation_config.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_grouped_resources_view.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_home_tile.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_nav_footer.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_nav_header.dart';
import 'package:crud_o/dashboard/presentation/widgets/crudo_nav_tile.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o_core/resources/resource_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrudoSideBar extends StatefulWidget {
  final Widget home;
  final CrudoNavigationConfig? config;
  final double? sidebarWidth;

  const CrudoSideBar({
    super.key,
    required this.home,
    this.config,
    this.sidebarWidth,
  });

  @override
  State<CrudoSideBar> createState() => _CrudoSideBarState();
}

class _CrudoSideBarState extends State<CrudoSideBar> {
  final GlobalKey<NavigatorState> _contentNavKey = GlobalKey<NavigatorState>();
  String _currentRoute = '/';

  static const String _defaultGroup = '';

  /// Navigation inside the CONTENT navigator (sidebar-style: clear stack)
  void _go(String routeName) {
    if (_currentRoute == routeName) return;
    setState(() => _currentRoute = routeName);

    _contentNavKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
          (route) => false,
    );
  }

  String _routeNameOfResource(BuildContext context, CrudoResource resource) {
    final registered = context.read<RegisteredResources>();
    final idx = registered.resources.indexOf(resource);
    return '/r/$idx';
  }

  /// Lookup extra item by route name
  CrudoExtraNavItem? _findExtraByRouteName(String routeName) {
    final extras = widget.config?.extraItems ?? const <CrudoExtraNavItem>[];
    for (final e in extras) {
      if (e.routeName == routeName) return e;
    }
    return null;
  }

  Future<bool> _onWillPop() async {
    final nav = _contentNavKey.currentState!;
    if (nav.canPop()) {
      nav.pop();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeConfig = CrudoConfiguration.theme();
    final effectiveSidebarWidth = widget.sidebarWidth ?? themeConfig.sidebarWidth;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: themeConfig.sidebarBackgroundColor ?? cs.surfaceContainerHighest,
        body: Row(
          children: [
            SizedBox(
              width: effectiveSidebarWidth,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      CrudoNavHeader(
                        config: widget.config,
                        avatarRadius: themeConfig.navHeaderAvatarRadiusSidebar,
                        fontSize: themeConfig.navHeaderFontSizeSidebar,
                      ),
                      CrudoHomeTile(
                        currentRoute: _currentRoute,
                        onTap: () => _go('/'),
                      ),

                      // Resources + extra items mixed and ordered
                      CrudoGroupedResourcesView<_NavEntry>(
                        futureBuilder: () => _getAvailableEntries(context),
                        itemBuilder: (context, entry) {
                          // EXTRA ITEM (behaves like resources)
                          if (entry.extra != null) {
                            final e = entry.extra!;
                            final selected = _currentRoute == e.routeName;

                            return CrudoNavTile(
                              selected: selected,
                              icon: e.icon,
                              title: e.title,
                              navigationOrder: e.navigationOrder,
                              onTap: () async {
                                final safeCtx =
                                    _contentNavKey.currentContext ?? context;

                                // ACTION mode
                                if (e.onTap != null) {
                                  await e.onTap!(safeCtx);
                                  return;
                                }

                                // If already selected and replaceOnReselect is true, re-navigate
                                if (selected && e.replaceOnReselect) {
                                  _contentNavKey.currentState!.pushNamedAndRemoveUntil(
                                    e.routeName,
                                    (route) => false,
                                  );
                                  return;
                                }

                                // NAVIGATION mode (stack cleared like resources)
                                _go(e.routeName);
                              },
                            );
                          }

                          // RESOURCE
                          final resource = entry.resource!;
                          final route = _routeNameOfResource(context, resource);

                          return CrudoNavTile(
                            selected: _currentRoute == route,
                            icon: resource.icon(),
                            title: resource.pluralName(),
                            navigationOrder: entry.order,
                            onTap: () => _go(route),
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CrudoNavFooter(config: widget.config),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // CONTENT
            Expanded(
              child: Navigator(
                key: _contentNavKey,
                initialRoute: '/',
                onGenerateRoute: (settings) {
                  final name = settings.name ?? '/';

                  // HOME
                  if (name == '/') {
                    return MaterialPageRoute(
                      settings: settings,
                      builder: (_) => widget.home,
                    );
                  }

                  // EXTRA ROUTES (named, so selection/back behavior matches resources)
                  final extra = _findExtraByRouteName(name);
                  if (extra != null) {
                    final builder = extra.pageBuilder;
                    if (builder == null) {
                      return MaterialPageRoute(
                        settings: settings,
                        builder: (_) => const Scaffold(
                          body: Center(
                            child: Text('No pageBuilder for this nav item'),
                          ),
                        ),
                      );
                    }

                    return MaterialPageRoute(
                      settings: settings,
                      builder: (_) => builder(context),
                    );
                  }

                  // RESOURCES: /r/<index>
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
          ],
        ),
      ),
    );
  }

  Future<Map<String, List<_NavEntry>>> _getAvailableEntries(
      BuildContext context) async {
    final resourcesWithTables = context
        .read<RegisteredResources>()
        .resources
        .where((e) => e.tablePage != null)
        .toList();

    final grouped = <String, List<_NavEntry>>{};

    // 1) Extra ITEMS into default group (no ExpansionTile)
    final extras = widget.config?.extraItems ?? const <CrudoExtraNavItem>[];
    if (extras.isNotEmpty) {
      grouped.putIfAbsent(_defaultGroup, () => []);
      for (final e in extras) {
        grouped[_defaultGroup]!.add(
          _NavEntry.extra(e, order: e.navigationOrder),
        );
      }
    }

    // 2) Resources grouped
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

    // 3) Sort groups: default '' first, then alphabetically
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