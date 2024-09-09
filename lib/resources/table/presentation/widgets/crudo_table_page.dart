import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_column_menu.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_footer.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class CrudoTablePage<TResource extends CrudoResource<TModel>, TModel>
    extends StatelessWidget {
  late PlutoGridStateManager tableManager;

  CrudoTablePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CrudoTableBloc>(
        create: (context) => CrudoTableBloc<TResource, TModel>(
            resource: context.read<TResource>()),
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
    var columns = context.read<TResource>().getColumns();
    if (context.read<TResource>().tableActions().isNotEmpty) {
      columns.add(_buildActionsColumn());
    }
    return PlutoGrid(
      configuration: const PlutoGridConfiguration(
        columnSize: PlutoGridColumnSizeConfig(
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
      actions: context.read<TResource>().canCreate
          ? [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            context.read<TResource>().formPage!),
                  );
                },
              )
            ]
          : [],
      title: BlocBuilder<CrudoTableBloc, CrudoTableState>(
        builder: (context, state) {
          return AnimatedSearchBar(
            label: context.read<TResource>().pluralName(),
            labelStyle: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            duration: const Duration(milliseconds: 300),
            animationDuration: const Duration(milliseconds: 300),
            searchDecoration: const InputDecoration(
              hintText: 'Cerca',
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
      ),
    );
  }

  /// Called when got new data from the bloc
  void onDataLoaded(
      BuildContext context, PaginatedResourceResponse<TModel> response) {
    tableManager.removeAllRows();
    for (var item in response.data) {
      // Create data row from the item
      var dataRow = PlutoRow(cells: context.read<TResource>().toCells(item));

      // Create actions cell
      if (context.read<TResource>().tableActions().isNotEmpty) {
        dataRow.cells['actions'] =
            PlutoCell(value: context.read<TResource>().getId(item));
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
    if (state is TableErrorState) {
      Toaster.error(state.error.toString());
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
      renderer: (columnContext) => PopupMenuButton(
        padding: const EdgeInsets.only(right: 10),
        icon: const Icon(Icons.more_vert),
        itemBuilder: (context) =>
            context.read<TResource>().tableActions().map((action) {
          return PopupMenuItem(
            onTap: () {
              action.execute(context, data: {'id': columnContext.cell.value});
            },
            child: ListTile(
              leading: Icon(action.icon, color: action.color),
              title: Text(action.label, style: TextStyle(color: action.color)),
            ),
          );
        }).toList(),
      ),
    );
  }
}
