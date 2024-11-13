import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/common/dialogs/confirmation_dialog.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/resources/form/data/form_result.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_factory.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:crud_o/resources/resource_policy.dart';
import 'package:crud_o/resources/resource_repository.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'table/bloc/crudo_table_bloc.dart';

abstract class CrudoResource<TModel extends dynamic> extends Object {
  final ResourceRepository<TModel> repository;
  final ResourcePolicy<TModel>? policy;
  CrudoResource({required this.repository, this.policy});

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

  String group() => '';

  Map<String, dynamic> toMap(TModel model) => throw UnimplementedError();

  /// **************************************************************************************************
  /// ACTIONS
  /// **************************************************************************************************
  Future<CrudoAction?> createAction() async {
    if (formPage == null) return null;
    if(policy != null && !(await policy!.create())) return null;
    return CrudoAction(
        label: 'Crea',
        icon: Icons.add,
        action: (context, data) async {
          return await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RepositoryProvider(
                      create: (context) => ResourceContext(
                          id: "",
                          data: data ?? {},
                          operationType: ResourceOperationType.create),
                      child: formPage,
                    )),
          );
        });
  }

  Future<CrudoAction?> editAction(TModel model) async {
    if (formPage == null) return null;
    if(policy != null && !(await policy!.update(model))) return null;
    return CrudoAction(
        label: 'Modifica',
        icon: Icons.edit,
        action: (context, data) async {
          return await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RepositoryProvider(
                      create: (context) => ResourceContext(
                          id: getId(model).toString(),
                          data: data ?? {},
                          model: model,
                          operationType: ResourceOperationType.edit),
                      child: formPage,
                    )),
          );
        });
  }

  Future<CrudoAction?> viewAction(TModel model) async {
    if (formPage == null) return null;
    if(policy != null && !(await policy!.view(model))) return null;
    return CrudoAction(
        label: 'Visualizza',
        icon: Icons.remove_red_eye,
        action: (context, data) async {
         return await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => RepositoryProvider(
                      create: (context) => ResourceContext(
                          id: getId(model).toString(),
                          data: data ?? {},
                          model: model,
                          operationType: ResourceOperationType.view),
                      child: formPage,
                    )),
          );
        });
  }

  Future<CrudoAction?> deleteAction(TModel model) async {
    if(policy != null && !(await policy!.delete(model))) return null;
    return CrudoAction(
        label: 'Elimina',
        icon: Icons.delete,
        color: Colors.red,
        action: (context, data) async {
          // Ask for confirmation
          var confirmed = await ConfirmationDialog.ask(
              context: context,
              title: 'Elimina ${singularName()}',
              message: 'Sei sicuro di voler procedere?');

          if (!confirmed) {
            return ActionResult();
          }

          // Actually delete the resource
          try {
            await repository.delete(getId(model));
          } catch (e) {
            Toaster.error('Errore durante l\'eliminazione');
            return ActionResult();
          }

          // Get table state and reload
          var tableState = context.read<CrudoTableBloc>().state;
          if (tableState is TableLoadedState) {
            context
                .read<CrudoTableBloc>()
                .add(UpdateTableEvent(tableState.request));
          }
          return ActionResult(refreshTable: true);
        });
  }

  /// Form to edit/create/view the resource
  Widget? formPage;

  /// Table to show the resource
  Widget? tablePage;

  /// **************************************************************************************************
  /// SHORTCUTS
  /// **************************************************************************************************
  ResourceFactory<TModel> get factory => repository.factory;
  TRepository getRepository<TRepository extends ResourceRepository<TModel>>() => repository as TRepository;
}
