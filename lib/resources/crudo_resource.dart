import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/common/dialogs/confirmation_dialog.dart';
import 'package:crud_o/resources/form/presentation/pages/crudo_form_page.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_serializer.dart';
import 'package:crud_o/resources/resource_repository.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:crud_o/resources/view/presentation/pages/crudo_view_page.dart';
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

  IconData icon() => Icons.folder;


  /// **************************************************************************************************
  /// TABLE
  /// **************************************************************************************************

  /// Override this method to define the columns of the table
  List<PlutoColumn> getColumns() {
    return [];
  }

  /// Override this method to define the actions that can be performed on the resource in the table
  List<CrudoAction> tableActions() {
    var actions = <CrudoAction>[];
    if(editAction() != null) actions.add(editAction()!);
    if(viewAction() != null) actions.add(viewAction()!);
    if(canDelete) actions.add(deleteAction());
    return actions;
  }


  /// **************************************************************************************************
  /// ACTIONS
  /// **************************************************************************************************
  CrudoAction? editAction() {
    if (formPage == null) return null;
    return CrudoAction(
        label: 'Modifica',
        icon: Icons.edit,
        action: (context, data) async {
          return await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RepositoryProvider(
                      create: (context) => ResourceContext(id: data?['id']),
                      child: formPage!,
                    )),
          );
        });
  }

  CrudoAction? viewAction() {
    if (viewPage == null) return null;
    return CrudoAction(
        label: 'Visualizza',
        icon: Icons.remove_red_eye,
        action: (context, data) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RepositoryProvider(
                      create: (context) => ResourceContext(id: data?['id']),
                      child: viewPage!,
                    )),
          );
        });
  }

  CrudoAction deleteAction() {
    return CrudoAction(
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
        });
  }

  /// Form to edit/create the resource
  CrudoFormPage? formPage;

  /// View to show the resource
  CrudoViewPage? viewPage;

  /// Override this method to define if the resource can be created
  bool get canCreate => formPage != null;

  /// Override this method to define if the resource can be deleted
  bool get canDelete => true;
}
