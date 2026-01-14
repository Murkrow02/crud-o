import 'package:crud_o/resources/table/data/controllers/crudo_table_settings_controller.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class CrudoTableSettingsPopup extends StatefulWidget {
  final CrudoTableSettingsController settingsController;

  const CrudoTableSettingsPopup({
    super.key,
    required this.settingsController,
  });

  @override
  State<CrudoTableSettingsPopup> createState() =>
      _CrudoTableSettingsPopupState();
}

class _CrudoTableSettingsPopupState extends State<CrudoTableSettingsPopup> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleColumns = widget.settingsController.columns
        .where((col) => col.canBeManuallyHidden)
        .toList();
    final visibleCount = visibleColumns.where((col) => col.visible).length;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.view_column_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gestisci colonne',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$visibleCount di ${visibleColumns.length} visibili',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Select all / Deselect all
                  IconButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      final allVisible = visibleCount == visibleColumns.length;
                      for (var i = 0; i < widget.settingsController.columns.length; i++) {
                        if (widget.settingsController.columns[i].canBeManuallyHidden) {
                          widget.settingsController.handleColumnVisibilityChange(i, !allVisible);
                        }
                      }
                      setState(() {});
                    },
                    icon: Icon(
                      visibleCount == visibleColumns.length
                          ? Icons.deselect_rounded
                          : Icons.select_all_rounded,
                      color: colorScheme.primary,
                    ),
                    tooltip: visibleCount == visibleColumns.length
                        ? 'Nascondi tutte'
                        : 'Mostra tutte',
                  ),
                ],
              ),
            ),

            // Column list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.settingsController.columns.length,
                separatorBuilder: (_, __) => const SizedBox.shrink(),
                itemBuilder: (context, index) {
                  final column = widget.settingsController.columns[index];

                  if (!column.canBeManuallyHidden) {
                    return const SizedBox.shrink();
                  }

                  return _buildColumnTile(context, column, index);
                },
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Fatto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnTile(BuildContext context, dynamic column, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          widget.settingsController.handleColumnVisibilityChange(
            index,
            !column.visible,
          );
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: column.visible
                    ? colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: column.visible
                      ? colorScheme.primary
                      : colorScheme.outline,
                  width: 2,
                ),
              ),
              child: column.visible
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: colorScheme.onPrimary,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                column.column.title,
                style: TextStyle(
                  color: column.visible
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: column.visible ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              column.visible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              size: 20,
              color: column.visible
                  ? colorScheme.primary.withOpacity(0.7)
                  : colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}
