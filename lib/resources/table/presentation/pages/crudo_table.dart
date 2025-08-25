import 'dart:async';
import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:crud_o_core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o_core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o_core/resources/actions/crudo_action.dart';
import 'package:crud_o_core/resources/actions/crudo_action_result.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:crud_o/resources/table/data/controllers/crudo_table_settings_controller.dart';
import 'package:crud_o/resources/table/data/crudo_table_context.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_column.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_column_menu.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_filters_popup.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_footer.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o/resources/table/presentation/widgets/crudo_table_settings_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futuristic/futuristic.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CrudoTable<TResource extends CrudoResource<TModel>, TModel>
    extends StatelessWidget {
  final List<CrudoTableColumn<TModel>> Function(BuildContext context)
      columnBuilder;
  final List<CrudoAction>? additionalRowActions;
  final bool searchable;
  final bool enableColumnHiding;
  final Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)?
      customFuture;
  final List<TModel>? customData;

  // Customize before and after the table
  // Useful when using full page display
  final Widget Function(
          Widget table, CrudoTableContext<TResource, TModel> tableContext)?
      tableWrapperBuilder;

  // Map of data to pass to the resources.actions,
  final Map<String, dynamic>? actionData;
  final CrudoTableDisplayType displayType;
  final bool paginated;
  final Function(BuildContext context,
      CrudoTableContext<TResource, TModel> tableContext)? filtersFormBuilder;

  // Useful when need to get the table context
  final Function(CrudoTableContext<TResource, TModel> tableContext)?
      onTableCreated;

  // Called whenever the data in the table changes, bool indicates first load
  final Function(bool firstLoad)? onDataChanged;

  const CrudoTable({
    required this.columnBuilder,
    this.additionalRowActions,
    this.searchable = false,
    this.enableColumnHiding = false,
    this.customFuture,
    this.displayType = CrudoTableDisplayType.widget,
    this.paginated = false,
    this.tableWrapperBuilder,
    this.onDataChanged,
    this.actionData,
    this.customData,
    this.filtersFormBuilder,
    this.onTableCreated,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure that only one of customData and customFuture is provided
    assert(customData == null || customFuture == null,
        'Cannot provide both customData and customFuture');

    // Create table context
    var resource = context.read<TResource>();
    defaultFuture(PaginatedRequest request) async {
      return await resource.getRepository().getPaginated(request: request);
    }

    // Create the table context
    var tableContext = CrudoTableContext<TResource, TModel>(
        resource: resource,

        // First check for custom data and create a future from that, then check for custom future finally default future
        initialTableFuture: customData != null
            ? (PaginatedRequest request) =>
                Future.value(SinglePageResponse<TModel>(data: customData ?? []))
            : customFuture ?? defaultFuture);

    // Create the table bloc
    return BlocProvider<CrudoTableBloc>(
      create: (context) {
        final bloc = CrudoTableBloc<TResource, TModel>(
          resource: context.read(),
          tableContext: tableContext,
        );
        tableContext.bloc = bloc; // Assign bloc before returning.
        return bloc;
      },
      child: Provider(
        create: (context) => tableContext,
        child: BlocConsumer<CrudoTableBloc, CrudoTableState>(
          listener: _tableStateEventListener,
          builder: (context, state) {
            return _buildTableWrapper(
                context, _buildTable(context), tableContext);
          }
        ),
      ),
    );
  }

  /// Create the table widget
  Widget _buildTable(BuildContext context) {
    var columns = columnBuilder(context);
    return PlutoGrid(
      configuration: _getGridConfiguration(context),
      columnMenuDelegate: CrudoTableColumnMenu(),
      onSorted: (PlutoGridOnSortedEvent event) =>
          _onTableSorted(event, context),
      noRowsWidget: const Center(
          child: Text('Nessun elemento', style: TextStyle(fontSize: 20))),
      onLoaded: (PlutoGridOnLoadedEvent event) async {
        var tableContext = context.readTableContext<TResource, TModel>();
        tableContext.tableManager = event.stateManager;
        tableContext.tableManager.setSelectingMode(PlutoGridSelectingMode.row);
        tableContext.settingsController = CrudoTableSettingsController(
            columns: columns,
            tableManager: tableContext.tableManager,
            resource: tableContext.resource);
        await tableContext.settingsController.hideColumns();
        onTableCreated?.call(tableContext);
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
  Widget _buildTableWrapper(BuildContext context, Widget table,
      CrudoTableContext<TResource, TModel> tableContext) {
    switch (displayType) {
      case CrudoTableDisplayType.widget:
        return _buildWidgetWrapper(context, table, tableContext);
      case CrudoTableDisplayType.fullPage:
        return _buildFullPageWrapper(context, tableContext);
    }
  }

  /// Wrapper when table is displayed as a widget
  Widget _buildWidgetWrapper(BuildContext context, Widget table,
      CrudoTableContext<TResource, TModel> tableContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (enableColumnHiding)
              _buildColumnHidingButton(context, tableContext),
            _buildCreateActionButton(context),
          ],
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          margin: const EdgeInsets.all(10),
          child: _buildTable(context),
        )
      ],
    );
  }

  /// Wrapper when table is displayed as a full page
  Widget _buildFullPageWrapper(
      BuildContext context, CrudoTableContext<TResource, TModel> tableContext) {
    return Scaffold(
      appBar: AppBar(
          title: searchable
              ? _buildSearchBar(context)
              : Text(context.read<TResource>().pluralName()),
          actions: [
            if (enableColumnHiding)
              _buildColumnHidingButton(context, tableContext),
            _buildFiltersPopMenuButton(context),
            _buildCreateActionButton(context)
          ]),
      body: Container(
          margin: const EdgeInsets.all(10),
          child: tableWrapperBuilder != null
              ? tableWrapperBuilder!(_buildTable(context), context.readTableContext<
                  TResource, TModel>())
              : _buildTable(context)),
    );
  }

  /// Use a custom search bar to search the table
  Widget _buildSearchBar(BuildContext context) {
    return BlocBuilder<CrudoTableBloc, CrudoTableState>(
      builder: (context, state) {
        return AnimatedSearchBar(
          label: context.read<TResource>().pluralName(),
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
                  request: state.request.copyWith(search: value, page: 1)));
            }
          },
          onClose: () {
            if (state is TableLoadedState<TModel>) {
              context.read<CrudoTableBloc>().add(UpdateTableEvent(
                  request: state.request.copyWith(search: '', page: 1)));
            }
          },
        );
      },
    );
  }

  // Listen to table state events
  void _tableStateEventListener(BuildContext context, CrudoTableState state) {
    context
        .readTableContext<TResource, TModel>()
        .tableManager
        .setShowLoading(false);

    if (state is TableLoadingState) {
      context
          .readTableContext<TResource, TModel>()
          .tableManager
          .setShowLoading(true);
    }
    if (state is TableLoadedState<TModel>) {
      _onDataLoaded(context, state.response);
      onDataChanged
          ?.call(context.readTableContext<TResource, TModel>().firstLoad);
      if (context.readTableContext<TResource, TModel>().firstLoad) {
        context.readTableContext<TResource, TModel>().firstLoad = false;
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
    context.readTableContext<TResource, TModel>().tableManager.removeAllRows();

    // Create rows
    for (var item in response.data) {
      // Row cells for data info
      var dataRow = PlutoRow(cells: _getCells(item, context));

      // Row cells for resources.actions
      dataRow.cells['resources.actions'] = PlutoCell(value: item);

      context
          .readTableContext<TResource, TModel>()
          .tableManager
          .refRows
          .add(dataRow);
    }
  }

  /// The last column of the table, a popup menu with resources.actions
  PlutoColumn _buildActionsColumn() {
    return PlutoColumn(
      title: '',
      field: 'resources.actions',
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
          futureBuilder: () => _getActionsForItem(context, item),
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
                    var actionResult = res as CrudoActionResult;
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
  Map<String, PlutoCell> _getCells(TModel model, BuildContext context) {
    return Map.fromEntries(
      columnBuilder(context).map(
        (mapping) => MapEntry(mapping.column.field, mapping.cellBuilder(model)),
      ),
    );
  }

  /// Create a new item
  void _onCreateClicked(BuildContext context) async {
    var createAction = await context.read<TResource>().createAction();
    if (createAction == null) return;
    createAction.execute(context, data: actionData).then((res) {
      var actionResult = res as CrudoActionResult;
      if (actionResult.refreshTable == true) {
        refreshTable(context);
      }
    });
  }

  /// Create a list of possible resources.actions for the table
  Future<List<CrudoAction>> _defaultTableActionsForItem(
      BuildContext context, TModel item) async {
    var actions = <CrudoAction>[];

    // View
    var viewAction = await context.read<TResource>().viewAction(item);
    if (viewAction != null) {
      actions.add(viewAction);
    }

    // Edit
    var editAction = await context.read<TResource>().editAction(item);
    if (editAction != null) {
      actions.add(editAction);
    }

    // Delete
    var deleteAction = await context.read<TResource>().deleteAction(item);
    if (deleteAction != null) {
      actions.add(deleteAction);
    }

    return actions;
  }

  /// Add the default resources.actions to the custom resources.actions
  Future<List<CrudoAction>> _getActionsForItem(
      BuildContext context, TModel item) async {
    var defaultActions = await _defaultTableActionsForItem(context, item);
    return defaultActions..insertAll(0,additionalRowActions ?? []);
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
      context.read<CrudoTableBloc>().add(UpdateTableEvent(
          request: state.request.copyWith(page: state.request.page)));
      return;
    }

    // If the table is not loaded, load it from scratch
    context.read<CrudoTableBloc>().add(LoadTableEvent());
  }

  Widget _buildColumnHidingButton(
      BuildContext context, CrudoTableContext<TResource, TModel> tableContext) {
    return IconButton(
      icon: const Icon(Icons.visibility),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => CrudoTableSettingsPopup(
            settingsController: tableContext.settingsController,
          ),
        );
      },
    );
  }

  Widget _buildCreateActionButton(BuildContext context) {
    return Futuristic<CrudoAction?>(
        autoStart: true,
        futureBuilder: () => context.read<TResource>().createAction(),
        busyBuilder: (_) => const SizedBox(),
        dataBuilder: (context, action) => action == null
            ? const SizedBox()
            : IconButton(
                icon: Icon(action.icon),
                onPressed: () => _onCreateClicked(context),
              ));
  }

  Widget _buildFiltersPopMenuButton(BuildContext context) {
    if (filtersFormBuilder == null) return const SizedBox();
    var tableContext = context.readTableContext<TResource, TModel>();
    return CrudoTableFiltersPopup<TResource, TModel>(
        tableContext: tableContext, filtersFormBuilder: filtersFormBuilder!);

    // // Open a tooltip from here to include a custom widget inside
    // return Tooltip(
    //   message: 'Filtri',
    //   child: IconButton(
    //     icon: const Icon(Icons.filter_alt_outlined),
    //     onPressed: () {
    //       showDialog(
    //         context: context,
    //         builder: (context) => Text("ASD")
    //       );
    //     },
    //   ),
    // );
    //
    //
    // // Button with dropdown
    // return PopupMenuButton(
    //   icon: const Icon(Icons.filter_alt_outlined),
    //   tooltip: 'Filtri',
    //   itemBuilder: (context) {
    //     return filters!.map((filter) {
    //       return PopupMenuItem(
    //         child: ListTile(
    //           leading: filter.icon == null ? null : Icon(filter.icon),
    //           title: Text(filter.label),
    //           trailing: Icon(tableContext.isFilterActive(filter)
    //               ? Icons.check
    //               : Icons.check_box_outline_blank),
    //           onTap: () {
    //             Navigator.pop(context);
    //             tableContext.toggleFilter(filter);
    //             // context.readTableContext().setFuture(filter.future);
    //           },
    //         ),
    //       );
    //     }).toList();
    //   },
    // );
  }

  /// Called whenever a column is sorted
  void _onTableSorted(PlutoGridOnSortedEvent event, BuildContext context) {
    var state = context.read<CrudoTableBloc>().state;
    if (state is TableLoadedState<TModel>) {
      context.read<CrudoTableBloc>().add(UpdateTableEvent(
          request: state.request.copyWith(
              sortBy: SortParameter(
                  event.column.field,
                  event.column.sort.isAscending
                      ? SortDirection.asc
                      : SortDirection.desc))));
    }
  }
}

enum CrudoTableDisplayType { fullPage, widget }
