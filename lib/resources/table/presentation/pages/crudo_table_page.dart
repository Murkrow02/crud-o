import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_column.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_column_menu.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_footer.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

abstract class CrudoTablePage<TResource extends CrudoResource<TModel>, TModel>
    extends StatelessWidget {
  late PlutoGridStateManager tableManager;
  late TResource resource;

  CrudoTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get resource
    resource = context.read();

    return BlocProvider<CrudoTableBloc>(
        create: (context) =>
            CrudoTableBloc<TResource, TModel>(resource: resource),
        child: Builder(builder: (context) {
          return Scaffold(
            appBar: _buildAppBar(context),
            body: BlocListener<CrudoTableBloc, CrudoTableState>(
                listener: tableStateEventListener, child: _buildTable(context)),
          );
        }));
  }

  // The actual table widget
  Widget _buildTable(BuildContext context) {
    var columns = getColumns();
    if (tableActions().isNotEmpty) {
      columns.add(_buildActionsColumn());
    }
    return PlutoGrid(
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          columnTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          gridBackgroundColor: Theme.of(context).colorScheme.surface,
          cellTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          rowColor: Theme.of(context).colorScheme.surface,
        ),
        columnSize: const PlutoGridColumnSizeConfig(
          autoSizeMode: PlutoAutoSizeMode.none,
          resizeMode: PlutoResizeMode.none,
        ),
      ),
      columnMenuDelegate: CrudoTableColumnMenu(),
      onLoaded: (PlutoGridOnLoadedEvent event) {
        tableManager = event.stateManager;
        tableManager.setSelectingMode(PlutoGridSelectingMode.row);
        context.read<CrudoTableBloc>().add(LoadTableEvent());
      },
      columns: columns,
      rows: [],
      // DO NOT PUT CONST HERE
      createFooter: (tableManager) =>
          CrudoTableFooter(tableManager: tableManager),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      actions: resource.canCreate
          ? [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => resource.formPage!),
                  );
                },
              )
            ]
          : [],
      title: resource.canSearch
          ? _buildSearchBar(context)
          : Text(resource.pluralName()),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return BlocBuilder<CrudoTableBloc, CrudoTableState>(
      builder: (context, state) {
        return AnimatedSearchBar(
          label: resource.pluralName(),
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          duration: const Duration(milliseconds: 300),
          animationDuration: const Duration(milliseconds: 300),
          searchDecoration: InputDecoration(
            hintText: 'Cerca',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            alignLabelWithHint: true,
            border: InputBorder.none,
          ),
          height: 50,
          onFieldSubmitted: (value) {
            if (state is TableLoadedState<TModel>) {
              context.read<CrudoTableBloc>().add(UpdateTableEvent(
                  state.request.copyWith(search: value, page: 1)));
            }
          },
          onClose: () {
            if (state is TableLoadedState<TModel>) {
              context.read<CrudoTableBloc>().add(UpdateTableEvent(
                  state.request.copyWith(search: '', page: 1)));
            }
          },
        );
      },
    );
  }

  /// Called when got new data from the bloc
  void onDataLoaded(
      BuildContext context, PaginatedResourceResponse<TModel> response) {
    tableManager.removeAllRows();
    for (var item in response.data) {

      // Create data row from the item
      var dataRow = PlutoRow(cells: getCells(item));

      // Create actions cell
      if (tableActions().isNotEmpty) {
        dataRow.cells['actions'] = PlutoCell(value: resource.getId(item));
      }

      tableManager.refRows.add(dataRow);
    }
  }

  // Dispatch events based on the state
  void tableStateEventListener(BuildContext context, CrudoTableState state) {
    tableManager.setShowLoading(false);

    if (state is TableLoadingState) {
      tableManager.setShowLoading(true);
    }
    if (state is TableLoadedState<TModel>) {
      onDataLoaded(context, state.response);
    }
    if (state is TableErrorState && state.tracedError.error.toString() != '') {
      Toaster.error(state.tracedError.error.toString());
    }
  }

  // Build actions cell
  PlutoColumn _buildActionsColumn() {
    return PlutoColumn(
      title: '',
      field: 'actions',
      frozen: PlutoColumnFrozen.end,
      width: 40,
      enableDropToResize: false,
      enableColumnDrag: false,
      enableRowDrag: false,
      enableRowChecked: false,
      enableSorting: false,
      enableContextMenu: false,
      enableFilterMenuItem: false,
      type: PlutoColumnType.text(),
      renderer: (columnContext) => Builder(builder: (context) {
        return PopupMenuButton(
          padding: const EdgeInsets.only(right: 10),
          icon: Icon(Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface),
          itemBuilder: (context) => tableActions().map((action) {
            return PopupMenuItem(
              onTap: () async {
                action.execute(context, data: {
                  'id': columnContext.cell.value
                }).then((needToRefresh) {
                  if (needToRefresh == true) {
                    context.read<CrudoTableBloc>().add(LoadTableEvent());
                  }
                });
              },
              child: ListTile(
                leading: Icon(action.icon, color: action.color),
                title:
                    Text(action.label, style: TextStyle(color: action.color)),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  /// Override this method to define the actions that can be performed on the resource in the table
  List<CrudoAction> tableActions() {
    var actions = <CrudoAction>[];
    if (resource.editAction() != null) actions.add(resource.editAction()!);
    if (resource.viewAction() != null) actions.add(resource.viewAction()!);
    if (resource.canDelete) actions.add(resource.deleteAction());
    return actions;
  }

  /// Override this method to create the table columns and cells
  List<CrudoTableColumn<TModel>> buildColumns();

  /// Get only the columns from the buildColumns method
  List<PlutoColumn> getColumns() {
    return buildColumns().map((mapping) => mapping.column).toList();
  }

  Map<String, PlutoCell> getCells(TModel model) {
    return Map.fromEntries(
      buildColumns().map(
        (mapping) => MapEntry(mapping.column.field, mapping.cellBuilder(model)),
      ),
    );
  }
}
