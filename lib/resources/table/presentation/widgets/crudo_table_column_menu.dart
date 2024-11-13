import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class CrudoTableColumnMenu implements PlutoColumnMenuDelegate<CrudoTableMenuItem> {
  
  @override
  List<PopupMenuEntry<CrudoTableMenuItem>> buildMenuItems({
    required PlutoGridStateManager stateManager,
    required PlutoColumn column,
  }) {
    return [
        // const PopupMenuItem<CrudoTableMenuItem>(
        //   value: CrudoTableMenuItem.moveNext,
        //   height: 36,
        //   enabled: true,
        //   child: Text('Ordina decrescente (WIP)', style: TextStyle(fontSize: 13)),
        // ),
        // const PopupMenuItem<CrudoTableMenuItem>(
        //   value: CrudoTableMenuItem.movePrevious,
        //   height: 36,
        //   enabled: true,
        //   child: Text('Ordina crescente (WIP)', style: TextStyle(fontSize: 13)),
        // ),
    ];
  }

  @override
  void onSelected({
    required BuildContext context,
    required PlutoGridStateManager stateManager,
    required PlutoColumn column,
    required bool mounted,
    required CrudoTableMenuItem? selected,
  }) {
    switch (selected) {
      case CrudoTableMenuItem.moveNext:
        final targetColumn = stateManager.columns
            .skipWhile((value) => value.key != column.key)
            .skip(1)
            .first;

        stateManager.moveColumn(column: column, targetColumn: targetColumn);
        break;
      case CrudoTableMenuItem.movePrevious:
        final targetColumn = stateManager.columns.reversed
            .skipWhile((value) => value.key != column.key)
            .skip(1)
            .first;

        stateManager.moveColumn(column: column, targetColumn: targetColumn);
        break;
      case null:
        break;
    }
  }
}

enum CrudoTableMenuItem {
  moveNext,
  movePrevious,
}