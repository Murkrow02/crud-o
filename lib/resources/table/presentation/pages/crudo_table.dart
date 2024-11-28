import 'dart:async';

import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/form/data/form_result.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:crud_o/resources/table/data/controllers/crudo_table_settings_controller.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_column.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_filter.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_column_menu.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_footer.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_settings_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futuristic/futuristic.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrudoTable<TResource extends CrudoResource<TModel>, TModel>
    extends StatelessWidget {
  final List<CrudoTableColumn<TModel>> columns;
  final List<CrudoAction>? customActions;
  final bool searchable;
  final bool enableColumnHiding;
  final Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)?
      customFuture;
  final List<TModel>? customData;

  // Map of data to pass to the actions,
  final Map<String, dynamic>? actionData;
  final CrudoTableDisplayType displayType;
  final bool paginated;
  final List<CrudoTableFilter<TModel>>? filters;

  // Called whenever the data in the table changes, bool indicates first load
  final Function(bool firstLoad)? onDataChanged;

  CrudoTable({
    required this.columns,
    this.customActions,
    this.searchable = false,
    this.enableColumnHiding = false,
    this.customFuture,
    this.displayType = CrudoTableDisplayType.widget,
    this.paginated = false,
    this.onDataChanged,
    this.actionData,
    this.customData,
    this.filters,
    super.key,
  });

  // Used to control the table
  PlutoGridStateManager? tableManager;

  // Used to control table settings (CRUDO)
  CrudoTableSettingsController? settingsController;

  // The resource we are working with
  late TResource resource;

  // We need to keep track of the first load to avoid calling onDataChanged
  bool _firstLoad = true;

  @override
  Widget build(BuildContext context) {

    // Ensure that only one of customData and customFuture is provided
    assert(customData == null || customFuture == null,
        'Cannot provide both customData and customFuture');

    // Get resource for easier access
    resource = context.read();

    // Create the table bloc
    return BlocProvider<CrudoTableBloc>(
      create: (context) => CrudoTableBloc<TResource, TModel>(
          resource: resource,
          customFuture: customData != null  
              ? (PaginatedRequest request) => Future.value(
                  SinglePageResponse<TModel>(data: customData ?? []))
              : customFuture),
      child: Builder(
          builder: (context) => BlocListener<CrudoTableBloc, CrudoTableState>(
              listener: _tableStateEventListener,
              child: _buildTableWrapper(context, _buildTable(context)))),
    );
  }

  /// Create the table widget
  Widget _buildTable(BuildContext context) {
    return PlutoGrid(
      configuration: _getGridConfiguration(context),
      columnMenuDelegate: CrudoTableColumnMenu(),
      onSorted: (PlutoGridOnSortedEvent event) {
        var state = context.read<CrudoTableBloc>().state;
        if (state is TableLoadedState<TModel>) {
          context.read<CrudoTableBloc>().add(UpdateTableEvent(state.request
              .copyWith(
                  sortBy: SortParameter(
                      event.column.field,
                      event.column.sort.isAscending
                          ? SortDirection.asc
                          : SortDirection.desc))));
        }
      },
      noRowsWidget: const Center(
          child: Text('Nessun elemento', style: TextStyle(fontSize: 20))),
      onLoaded: (PlutoGridOnLoadedEvent event) async {
        tableManager = event.stateManager;
        tableManager!.setSelectingMode(PlutoGridSelectingMode.row);
        settingsController = CrudoTableSettingsController(
            columns: columns, tableManager: tableManager!, resource: resource);
        await settingsController!.hideColumns();
        context.read<CrudoTableBloc>().add(LoadTableEvent());
      },
      columns: columns.map((col) => col.column).toList()
        ..add(_buildActionsColumn()),
      rows: [],
      createFooter: (tableManager) => paginated
          ? CrudoTableFooter(tableManager: tableManager)
          : const SizedBox(),
    );
  }

  /// Create full page or simple widget table wrapper
  Widget _buildTableWrapper(BuildContext context, Widget table) {
    switch (displayType) {
      case CrudoTableDisplayType.widget:
        return _buildWidgetWrapper(context, table);
      case CrudoTableDisplayType.fullPage:
        return _buildFullPageWrapper(context);
    }
  }

  /// Wrapper when table is displayed as a widget
  Widget _buildWidgetWrapper(BuildContext context, Widget table) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (enableColumnHiding) _buildColumnHidingButton(context),
            _buildCreateActionButton(context),
          ],
        ),
        Container(
          height: 500,
          margin: const EdgeInsets.all(10),
          child: _buildTable(context),
        ),
      ],
    );
  }

  /// Wrapper when table is displayed as a full page
  Widget _buildFullPageWrapper(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: searchable
              ? _buildSearchBar(context)
              : Text(resource.pluralName()),
          actions: [
            if (enableColumnHiding) _buildColumnHidingButton(context),
            if (filters != null) _buildFiltersPopMenuButton(context),
            _buildCreateActionButton(context)
          ]),
      body: Container(
        margin: const EdgeInsets.all(10),
        child: _buildTable(context),
      ),
    );
  }

  /// Use a custom search bar to search the table
  Widget _buildSearchBar(BuildContext context) {
    return BlocBuilder<CrudoTableBloc, CrudoTableState>(
      builder: (context, state) {
        return AnimatedSearchBar(
          label: resource.pluralName(),
          labelStyle: const TextStyle(
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

  // Listen to table state events
  void _tableStateEventListener(BuildContext context, CrudoTableState state) {
    tableManager?.setShowLoading(false);

    if (state is TableLoadingState) {
      tableManager?.setShowLoading(true);
    }
    if (state is TableLoadedState<TModel>) {
      _onDataLoaded(context, state.response);
      onDataChanged?.call(_firstLoad);
      if (_firstLoad) {
        _firstLoad = false;
      }
    }
    if (state is TableErrorState && state.tracedError.error.toString() != '') {
      // Maybe provide a callback to handle error by the user
      // Toaster.error(state.tracedError.error.toString());
      debugPrint(state.tracedError.error.toString());
    }
  }

  /// Fired whenever there is new data to display
  void _onDataLoaded(
      BuildContext context, PaginatedResponse<TModel> response) async {
    // Clear all rows
    tableManager?.removeAllRows();

    // Create rows
    for (var item in response.data) {
      // Row cells for data info
      var dataRow = PlutoRow(cells: _getCells(item));

      // Row cells for actions
      dataRow.cells['actions'] = PlutoCell(value: item);

      tableManager?.refRows.add(dataRow);
    }
  }

  /// The last column of the table, a popup menu with actions
  PlutoColumn _buildActionsColumn() {
    return PlutoColumn(
      title: '',
      field: 'actions',
      frozen: PlutoColumnFrozen.end,
      width: 10,
      enableDropToResize: true,
      enableColumnDrag: false,
      enableRowDrag: false,
      enableRowChecked: false,
      enableSorting: false,
      enableContextMenu: false,
      enableFilterMenuItem: false,
      type: PlutoColumnType.text(),
      renderer: (columnContext) => Builder(builder: (context) {
        var item = columnContext.cell.value as TModel;
        return Futuristic<List<CrudoAction>>(
          futureBuilder: () => _getActionsForItem(item),
          autoStart: true,
          busyBuilder: (_) => const CircularProgressIndicator.adaptive(),
          dataBuilder: (context, actions) => actions == null || actions.isEmpty
              ? const SizedBox()
              : _buildActionsMenu(context, columnContext, item, actions),
        );
      }),
    );
  }

  Widget _buildActionsMenu(
      BuildContext context,
      PlutoColumnRendererContext columnContext,
      TModel item,
      List<CrudoAction> actions) {
    return PopupMenuButton(
        padding: const EdgeInsets.only(right: 10),
        icon: Icon(Icons.more_vert,
            color: Theme.of(context).colorScheme.onSurface),
        itemBuilder: (context) => actions.map((action) {
              return PopupMenuItem(
                onTap: () async {
                  action
                      .execute(context,
                          data: {
                            'id': columnContext.cell.value.id.toString(),
                            'model': item,
                          }..addAll(actionData ?? {}))
                      .then((res) {
                    var actionResult = res as ActionResult;
                    if (actionResult.refreshTable == true) {
                      refreshTable(context);
                    }
                  });
                },
                child: ListTile(
                  leading: Icon(action.icon, color: action.color),
                  title:
                      Text(action.label, style: TextStyle(color: action.color)),
                ),
              );
            }).toList());
  }

  /// Map the model to the cells of the table
  Map<String, PlutoCell> _getCells(TModel model) {
    return Map.fromEntries(
      columns.map(
        (mapping) => MapEntry(mapping.column.field, mapping.cellBuilder(model)),
      ),
    );
  }

  /// Create a new item
  void _onCreateClicked(BuildContext context) async {
    var createAction = await resource.createAction();
    if (createAction == null) return;
    createAction.execute(context, data: actionData).then((res) {
      var actionResult = res as ActionResult;
      if (actionResult.refreshTable == true) {
        refreshTable(context);
      }
    });
  }

  /// Create a list of possible actions for the table
  Future<List<CrudoAction>> _defaultTableActionsForItem(TModel item) async {
    var actions = <CrudoAction>[];

    // View
    var viewAction = await resource.viewAction(item);
    if (viewAction != null) {
      actions.add(viewAction);
    }

    // Edit
    var editAction = await resource.editAction(item);
    if (editAction != null) {
      actions.add(editAction);
    }

    // Delete
    var deleteAction = await resource.deleteAction(item);
    if (deleteAction != null) {
      actions.add(deleteAction);
    }

    return actions;
  }

  /// Add the default actions to the custom actions
  Future<List<CrudoAction>> _getActionsForItem(TModel item) async {
    var defaultActions = await _defaultTableActionsForItem(item);
    return defaultActions..addAll(customActions ?? []);
  }

  /// Configure plutogrid package
  PlutoGridConfiguration _getGridConfiguration(BuildContext context) {
    return PlutoGridConfiguration(
      style: PlutoGridStyleConfig(
        enableGridBorderShadow: false,
        enableColumnBorderVertical: false,
        enableColumnBorderHorizontal: true,
        enableCellBorderVertical: false,
        enableCellBorderHorizontal: true,
        borderColor: const Color(0xFFE1E1E1),
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
        resizeMode: PlutoResizeMode.normal,
      ),
    );
  }

  /// Call this method to refresh the table
  void refreshTable(BuildContext context) {
    var state = context.read<CrudoTableBloc>().state;

    // If the table is already loaded, just reload the data
    if (state is TableLoadedState<TModel>) {
      context.read<CrudoTableBloc>().add(
          UpdateTableEvent(state.request.copyWith(page: state.request.page)));
      return;
    }

    // If the table is not loaded, load it from scratch
    context.read<CrudoTableBloc>().add(LoadTableEvent());
  }

  Widget _buildColumnHidingButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.visibility),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => CrudoTableSettingsPopup(
            settingsController: settingsController!,
          ),
        );
      },
    );
  }

  Widget _buildCreateActionButton(BuildContext context) {
    return Futuristic<CrudoAction?>(
        autoStart: true,
        futureBuilder: () => resource.createAction(),
        busyBuilder: (_) => const SizedBox(),
        dataBuilder: (context, action) => action == null
            ? const SizedBox()
            : IconButton(
                icon: Icon(action.icon),
                onPressed: () => _onCreateClicked(context),
              ));
  }

  Widget _buildFiltersPopMenuButton(BuildContext context) {
    // Button with dropdown
    return PopupMenuButton(
      icon: const Icon(Icons.filter_alt_outlined),
      itemBuilder: (context) {
        return filters!.map((filter) {
          return PopupMenuItem(
            child: ListTile(
              leading: filter.icon == null ? null : Icon(filter.icon),
              title: Text(filter.label),
              onTap: () {
                Navigator.pop(context);

              },
            ),
          );
        }).toList();
      },
    );
  }
}

enum CrudoTableDisplayType { fullPage, widget }
