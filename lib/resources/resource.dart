import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/resources/resource_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

abstract class CrudoResource<TModel> extends Object {
  final ResourceRepository<TModel> repository;

  CrudoResource({required this.repository});

  String getId(TModel model);

  /// **************************************************************************************************
  /// TABLE
  /// **************************************************************************************************
  List<PlutoColumn> getColumns() {
    return [];
  }

  /// **************************************************************************************************
  /// DESERIALIZATION
  /// **************************************************************************************************

  // This method is used to convert the resource to a map
  // The map is used to serialize the model to a json and to map the model to a list of PlutoCells
  Map<String, dynamic> toMap(TModel model);

  /// This method is used to convert the resource to a list of PlutoCells to display in the grid
  /// Override to customize the conversion
  Map<String, PlutoCell> toCells(TModel model) {
    return toMap(model).map((propertyName, propertyValue) {
      return MapEntry(propertyName, PlutoCell(value: propertyValue));
    });
  }

  /// **************************************************************************************************
  /// ACTIONS
  /// **************************************************************************************************

  List<CrudoAction> tableActions() {
    return [
      if (editPage != null)
        CrudoAction(
            label: 'Modifica', icon: CupertinoIcons.pencil, action: (context, data) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => editPage!),
          );
        }),

      if (previewPage != null)
        CrudoAction(
            label: 'Visualizza', icon: CupertinoIcons.eye, action: (context, data) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => previewPage!),
          );
        }),

      if (createPage != null)
        CrudoAction(
            label: 'Crea', icon: CupertinoIcons.add,
            action: (context, data) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => createPage!),
          );
        }),
    ];
  }

  Widget? createPage;
  Widget? editPage;
  Widget? previewPage;

  /// This method is used to define the actions that can be performed on the resource
}
