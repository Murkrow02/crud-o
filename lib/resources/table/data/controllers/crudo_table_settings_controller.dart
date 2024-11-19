import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_column.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrudoTableSettingsController {
  final List<CrudoTableColumn> columns;
  final PlutoGridStateManager tableManager;
  final CrudoResource resource;

  const CrudoTableSettingsController(
      {required this.columns,
      required this.tableManager,
      required this.resource});

  String getSettingsName() {
    return '${resource.pluralName().hashCode}_hidden_columns';
  }

  /// Helper function to retrieve the hidden columns list from SharedPreferences
  Future<List<String>> _getHiddenColumns() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(getSettingsName()) ?? [];
  }

  /// Helper function to save the hidden columns list to SharedPreferences
  Future<void> _saveHiddenColumns(List<String> hiddenColumns) async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(getSettingsName(), hiddenColumns);
  }

  /// Handle visibility change for a column
  Future<void> handleColumnVisibilityChange(int index, bool visible) async {
    final column = columns[index];
    column.visible = visible;
    tableManager.hideColumn(column.column, !visible);

    // Retrieve and update hidden columns
    var hiddenColumns = await _getHiddenColumns();
    if (visible) {
      hiddenColumns.remove(column.column.field);
    } else {
      hiddenColumns.add(column.column.field);
    }

    // Save updated list
    await _saveHiddenColumns(hiddenColumns);
  }

  /// Apply hidden columns preferences to the table
  Future<void> hideColumns() async {
    var hiddenColumns = await _getHiddenColumns();
    for (var col in columns) {
      col.visible = !hiddenColumns.contains(col.column.field);
      if (!col.visible) {
        tableManager.hideColumn(col.column, true);
      }
    }
  }
}
