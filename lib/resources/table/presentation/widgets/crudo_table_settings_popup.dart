import 'package:crud_o/resources/table/data/controllers/crudo_table_settings_controller.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_column.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class CrudoTableSettingsPopup extends StatefulWidget {

  final CrudoTableSettingsController settingsController;
  const CrudoTableSettingsPopup(
      {super.key, required this.settingsController});

  @override
  State<CrudoTableSettingsPopup> createState() =>
      _ToggleColumnVisibilityPopupState();
}

class _ToggleColumnVisibilityPopupState
    extends State<CrudoTableSettingsPopup> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Colonne visibili'),
      content: SizedBox(
        width: 400,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate:  SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.of(context).size.width < 600 ? 1 : 2,
            childAspectRatio: MediaQuery.of(context).size.width < 600 ? 8 : 6,
          ),
          itemCount: widget.settingsController.columns.length,
          itemBuilder: (context, index) {
            if (!widget.settingsController.columns[index].canBeManuallyHidden) {
              return const SizedBox.shrink();
            }
            final column = widget.settingsController.columns[index];
            return Row(
              children: [
                Checkbox(
                  value: column.visible,
                  onChanged: (visible) {
                    setState(() {
                      widget.settingsController.handleColumnVisibilityChange(index, visible ?? false);
                    });
                  },
                ),
                Text(column.column.title),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
