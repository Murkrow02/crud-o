import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/common/dialogs/confirmation_dialog.dart';
import 'package:crud_o/resources/form/presentation/pages/crudo_form_page.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_repository.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

import 'table/bloc/crudo_table_bloc.dart';

abstract class CrudoResource<TModel extends dynamic> extends Object {
  final ResourceRepository<TModel> repository;

  CrudoResource({required this.repository});

  /// **************************************************************************************************
  /// RESOURCE INFO
  /// **************************************************************************************************

  /// Override this method to define the id of the resource
  /// By default it returns the id of the model
  String getId(TModel model) {
    return model.id!.toString();
  }

  String singularName();

  String pluralName();

  /// **************************************************************************************************
  /// FORM
  /// **************************************************************************************************

  /// Override this method to define how the model should be rendered into the form when editing an existing resource
  Map<String, dynamic> toFormData(TModel model) {
    return toMap(model);
  }

  /// **************************************************************************************************
  /// TABLE
  /// **************************************************************************************************

  /// Override this method to define the columns of the table
  List<PlutoColumn> getColumns() {
    return [];
  }

  /// Override this method to define the actions that can be performed on the resource in the table
  List<CrudoAction> tableActions() {
    return [
      if (formPage != null)
        CrudoAction(
            label: 'Modifica',
            icon: Icons.edit,
            action: (context, data) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RepositoryProvider(
                          create: (context) => ResourceContext(id: data?['id']),
                          child: formPage!,
                        )),
              );
            }),
      CrudoAction(
          label: 'Elimina',
          icon: Icons.delete,
          color: Colors.red,
          action: (context, data) async {

            // Ask for confirmation
            var confirmed = await ConfirmationDialog.ask(
                context: context,
                title: 'Elimina ${singularName()}',
                message: 'Sei sicuro di voler procedere?'
            );

            if (!confirmed) {
              return;
            }

            // Actually delete the resource
            await repository.delete(data?['id']);

            // Get table state and reload
            var tableState = context.read<CrudoTableBloc>().state;
            if (tableState is TableLoadedState) {
              context
                  .read<CrudoTableBloc>()
                  .add(UpdateTableEvent(tableState.request));
            }
          }),
    ];
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

  /// Form to edit/create the resource
  CrudoFormPage? formPage;

  /// Override this method to define if the resource can be created
  bool get canCreate => formPage != null;
}
