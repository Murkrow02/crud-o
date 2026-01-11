import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

class CrudoNavTile extends StatefulWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  final bool dense;
  final double? height;
  final double? iconSize;

  /// Determines ordering among tiles
  final int navigationOrder;

  const CrudoNavTile({
    super.key,
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
    required this.navigationOrder,
    this.dense = true,
    this.height,
    this.iconSize,
  });

  @override
  State<CrudoNavTile> createState() => _CrudoNavTileState();
}

class _CrudoNavTileState extends State<CrudoNavTile> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseTextStyle = Theme.of(context).textTheme.bodyLarge;
    final themeConfig = CrudoConfiguration.theme();

    final height = widget.height ?? themeConfig.navTileHeight;
    final iconSize = widget.iconSize ?? themeConfig.navTileIconSize;
    final borderRadius = themeConfig.navTileBorderRadius;
    final indicatorWidth = themeConfig.navTileIndicatorWidth;
    final indicatorHeight = themeConfig.navTileIndicatorHeight;

    final bg = widget.selected
        ? themeConfig.navTileSelectedBackgroundColor ?? cs.primaryContainer.withAlpha(isDark ? 80 : 20)
        : _isHovering
        ? themeConfig.navTileHoverBackgroundColor ?? cs.surfaceContainerHighest.withAlpha(isDark ? 40 : 40)
        : Colors.transparent;

    final fg = widget.selected
        ? themeConfig.navTileSelectedForegroundColor ?? cs.primary
        : themeConfig.navTileUnselectedForegroundColor ?? cs.onSurface.withAlpha(_isHovering ? 220 : 160);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: cs.primary.withOpacity(0.10),
            highlightColor: cs.primary.withOpacity(0.05),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: indicatorWidth,
                      height: widget.selected ? indicatorHeight : 0,
                      decoration: BoxDecoration(
                        color: themeConfig.navTileSelectedForegroundColor ?? cs.primary,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedScale(
                      scale: widget.selected ? 1.12 : 1.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        widget.icon,
                        size: iconSize,
                        color: fg,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        overflow: TextOverflow.ellipsis,
                        style: (baseTextStyle ?? const TextStyle()).copyWith(
                          color: fg,
                          fontWeight:
                          widget.selected ? FontWeight.w600 : FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}