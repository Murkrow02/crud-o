import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
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

class CrudoTable<TResource extends CrudoResource<TModel>, TModel>
    extends StatelessWidget {
  final List<CrudoTableColumn<TModel>> columns;
  final List<CrudoAction>? customActions;
  final bool searchable;
  final Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)?
      customFuture;

  // Map of data to pass to the actions,
  final Map<String, dynamic>? data;
  final bool fullPage;
  final bool paginated;

  // Called whenever the data in the table changes, bool indicates first load
  final Function(bool)? onDataChanged;

  CrudoTable({
    required this.columns,
    this.customActions,
    this.searchable = false,
    this.customFuture,
    this.fullPage = false,
    this.paginated = false,
    this.onDataChanged,
    this.data,
    Key? key,
  }) : super(key: key);

  late PlutoGridStateManager tableManager;
  late TResource resource;
  bool _firstLoad = true;

  @override
  Widget build(BuildContext context) {
    resource = context.read();

    return BlocProvider<CrudoTableBloc>(
      create: (context) => CrudoTableBloc<TResource, TModel>(
          resource: resource, customFuture: customFuture),
      child: Builder(
        builder: (context) {
          if (!fullPage) {
            return SizedBox(
                height: 500,
                child: BlocListener<CrudoTableBloc, CrudoTableState>(
                    listener: _tableStateEventListener,
                    child: Container(
                      margin: const EdgeInsets.all(10),
                      child: _buildTable(context),
                    )));
          }

          return Scaffold(
            appBar: _buildAppBar(context),
            body: BlocListener<CrudoTableBloc, CrudoTableState>(
                listener: _tableStateEventListener,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  child: _buildTable(context),
                )),
          );
        },
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    var plutoColumns = columns.map((col) => col.column).toList();
    if (_getActions().isNotEmpty) {
      plutoColumns.add(_buildActionsColumn());
    }
    return PlutoGrid(
      configuration: PlutoGridConfiguration(
        style: PlutoGridStyleConfig(
          enableGridBorderShadow: false,
          enableColumnBorderVertical: false,
          enableColumnBorderHorizontal: true,
          enableCellBorderVertical: false,
          enableCellBorderHorizontal: true,
          borderColor: Color(0xFFE1E1E1),
          cellUnselectedColor: Colors.transparent,
          evenRowColor: Colors.transparent,
          rowColor: Colors.transparent,
          gridBorderColor: Colors.transparent,
          columnTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          gridBackgroundColor: Colors.transparent,
          //Theme.of(context).colorScheme.surface,
          cellTextStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
          //rowColor: Theme.of(context).colorScheme.surface,
        ),
        columnSize: const PlutoGridColumnSizeConfig(
          autoSizeMode: PlutoAutoSizeMode.scale,
          resizeMode: PlutoResizeMode.none,
        ),
      ),
      columnMenuDelegate: CrudoTableColumnMenu(),
      onLoaded: (PlutoGridOnLoadedEvent event) {
        tableManager = event.stateManager;
        tableManager.setSelectingMode(PlutoGridSelectingMode.row);
        context.read<CrudoTableBloc>().add(LoadTableEvent());
      },
      columns: plutoColumns,
      rows: [],
      createFooter: (tableManager) => paginated
          ? CrudoTableFooter(tableManager: tableManager)
          : const SizedBox(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    var createAction = resource.createAction();
    return AppBar(
      actions: createAction != null
          ? [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => createAction
                    .execute(context, data: data)
                    .then((needToRefresh) {
                  if (needToRefresh == true) {
                    context.read<CrudoTableBloc>().add(LoadTableEvent());
                  }
                }),
              )
            ]
          : [],
      title: searchable ? _buildSearchBar(context) : Text(resource.pluralName()),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return BlocBuilder<CrudoTableBloc, CrudoTableState>(
      builder: (context, state) {
        return AnimatedSearchBar(
          label: resource.pluralName(),
          labelStyle: TextStyle(
            fontSize: 20,
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

  void _tableStateEventListener(BuildContext context, CrudoTableState state) {
    tableManager.setShowLoading(false);

    if (state is TableLoadingState) {
      tableManager.setShowLoading(true);
    }
    if (state is TableLoadedState<TModel>) {
      _onDataLoaded(context, state.response);
      onDataChanged?.call(_firstLoad);
      if (_firstLoad) {
        _firstLoad = false;
      }
    }
    if (state is TableErrorState && state.tracedError.error.toString() != '') {
      Toaster.error(state.tracedError.error.toString());
    }
  }

  void _onDataLoaded(BuildContext context, PaginatedResponse<TModel> response) {
    // Clear all rows
    tableManager.removeAllRows();

    // Create rows
    for (var item in response.data) {
      // Row cells for data info
      var dataRow = PlutoRow(cells: _getCells(item));

      // Row cells for actions
      var actions = _getActions();
      if (actions.isNotEmpty) {
        dataRow.cells['actions'] = PlutoCell(value: resource.getId(item));
      }

      tableManager.refRows.add(dataRow);
    }
  }

  PlutoColumn _buildActionsColumn() {
    return PlutoColumn(
      title: '',
      field: 'actions',
      frozen: PlutoColumnFrozen.end,
      width: 10,
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
          itemBuilder: (context) => _getActions().map((action) {
            return PopupMenuItem(
              onTap: () async {
                action
                    .execute(context,
                        data: {
                          'id': columnContext.cell.value,
                        }..addAll(data ?? {}))
                    .then((needToRefresh) {
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

  Map<String, PlutoCell> _getCells(TModel model) {
    return Map.fromEntries(
      columns.map(
        (mapping) => MapEntry(mapping.column.field, mapping.cellBuilder(model)),
      ),
    );
  }

  List<CrudoAction> _defaultTableActions() {
    var actions = <CrudoAction>[];
    if (resource.editAction() != null) actions.add(resource.editAction()!);
    if (resource.viewAction() != null) actions.add(resource.viewAction()!);
    if (resource.canDelete) actions.add(resource.deleteAction());
    return actions;
  }

  List<CrudoAction> _getActions() {
    return customActions ?? _defaultTableActions();
  }
}
