import 'dart:async';
import 'package:animated_search_bar/animated_search_bar.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
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
import 'package:flutter/services.dart';
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
  final bool createButtonAsFab;
  final double? widgetHeight;
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
    this.createButtonAsFab = false,
    this.widgetHeight,
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
      noRowsWidget: _buildEmptyStateWidget(context),
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // side: BorderSide(
        //   color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with title and actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                Text(
                  context.read<TResource>().pluralName(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (enableColumnHiding)
                  _buildIconButtonWithTooltip(
                    context: context,
                    icon: Icons.view_column_outlined,
                    tooltip: 'Gestisci colonne',
                    onPressed: () => _showColumnSettings(context, tableContext),
                  ),
                if (filtersFormBuilder != null)
                  _buildFiltersButton(context, tableContext),
                _buildCreateActionButton(context),
              ],
            ),
          ),
          const Divider(height: 1),
          // Table content
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: widgetHeight ?? MediaQuery.of(context).size.height * 0.5,
              child: _buildTable(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Wrapper when table is displayed as a full page
  Widget _buildFullPageWrapper(
      BuildContext context,
      CrudoTableContext<TResource, TModel> tableContext,
      ) {
    final themeConfig = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: themeConfig.tableGridBackgroundColor ?? colorScheme.surface,
      appBar: AppBar(
        backgroundColor: themeConfig.appBarBackgroundColor ?? colorScheme.surface,
        foregroundColor: themeConfig.appBarForegroundColor ?? colorScheme.onSurface,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: searchable
            ? _buildSearchBar(context)
            : Text(
                context.read<TResource>().pluralName(),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
        actions: [
          if (enableColumnHiding)
            _buildIconButtonWithTooltip(
              context: context,
              icon: Icons.view_column_outlined,
              tooltip: 'Gestisci colonne',
              onPressed: () => _showColumnSettings(context, tableContext),
            ),
          if (filtersFormBuilder != null)
            _buildFiltersButton(context, tableContext),
          if (!createButtonAsFab)
            _buildCreateActionButton(context),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // Active filters indicator
          _buildActiveFiltersBar(context, tableContext),
          // Main table content
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: tableWrapperBuilder != null
                    ? tableWrapperBuilder!(
                        _buildTable(context),
                        context.readTableContext<TResource, TModel>(),
                      )
                    : _buildTable(context),
              ),
            ),
          ),
        ],
      ),

      // Enhanced FAB
      floatingActionButton: createButtonAsFab
          ? Futuristic<CrudoAction?>(
              autoStart: true,
              futureBuilder: () => context.read<TResource>().createAction(),
              busyBuilder: (_) => const SizedBox(),
              dataBuilder: (context, action) => action == null
                  ? const SizedBox()
                  : FloatingActionButton.extended(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _onCreateClicked(context);
                      },
                      icon: Icon(action.icon),
                      label: Text(action.label),
                      elevation: 2,
                    ),
            )
          : null,
    );
  }

  /// Build active filters indicator bar
  Widget _buildActiveFiltersBar(BuildContext context,
      CrudoTableContext<TResource, TModel> tableContext) {
    return BlocBuilder<CrudoTableBloc, CrudoTableState>(
      builder: (context, state) {
        if (state is! TableLoadedState<TModel>) return const SizedBox();

        final filters = tableContext.getFiltersData();
        final activeFilters = filters.entries
            .where((e) => e.value != null && e.value.toString().isNotEmpty)
            .toList();

        if (activeFilters.isEmpty) return const SizedBox();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                Icons.filter_list,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              Text(
                'Filtri attivi:',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              ...activeFilters.map((filter) => Chip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(
                  '${filter.key}: ${filter.value}',
                  style: const TextStyle(fontSize: 11),
                ),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () {
                  final newFilters = Map<String, dynamic>.from(filters);
                  newFilters.remove(filter.key);
                  tableContext.setFilters(newFilters);
                },
              )),
              TextButton.icon(
                onPressed: () => tableContext.setFilters({}),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Rimuovi tutti', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Use a custom search bar to search the table
  Widget _buildSearchBar(BuildContext context) {
    var themeConfig = CrudoConfiguration.theme();
    return BlocBuilder<CrudoTableBloc, CrudoTableState>(
      builder: (context, state) {
        return AnimatedSearchBar(
          label: context.read<TResource>().pluralName(),
          searchIcon: Icon(
            Icons.search_rounded,
            color: themeConfig.tableSearchIconColor ??
                Theme.of(context).colorScheme.onSurface,
          ),
          closeIcon: Icon(
            Icons.close_rounded,
            color: themeConfig.tableSearchIconColor ??
                Theme.of(context).colorScheme.onSurface,
          ),
          labelStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          duration: const Duration(milliseconds: 250),
          animationDuration: const Duration(milliseconds: 250),
          searchDecoration: InputDecoration(
            hintText: 'Cerca...',
            hintStyle: TextStyle(
              color: themeConfig.tableSearchBarHintColor ??
                  Theme.of(context).colorScheme.onSurface,
            ),
            alignLabelWithHint: true,
            border: InputBorder.none,
          ),
          height: 48,
          onChanged: (value) {
            if (state is TableLoadedState<TModel>) {
              HapticFeedback.selectionClick();
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
      width: 56,
      enableDropToResize: false,
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
          busyBuilder: (_) => const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showActionsBottomSheet(context, columnContext, item, actions),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 22,
          ),
        ),
      ),
    );
  }

  void _showActionsBottomSheet(
      BuildContext context,
      PlutoColumnRendererContext columnContext,
      TModel item,
      List<CrudoAction> actions) {
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle indicator
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Actions list
                ...actions.map((action) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (action.color ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.color ?? Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    action.label,
                    style: TextStyle(
                      color: action.color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    HapticFeedback.selectionClick();
                    action.execute(
                      context,
                      data: {
                        'id': columnContext.cell.value.id.toString(),
                        'model': item,
                      }..addAll(actionData ?? {}),
                    ).then((res) {
                      var actionResult = res as CrudoActionResult;
                      if (actionResult.refreshTable == true) {
                        refreshTable(context);
                      }
                    });
                  },
                )),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
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
    final themeConfig = CrudoConfiguration.theme();

    return PlutoGridConfiguration(
      style: PlutoGridStyleConfig(
        enableGridBorderShadow: false,
        enableColumnBorderVertical: themeConfig.tableEnableColumnBorderVertical,
        enableColumnBorderHorizontal: themeConfig.tableEnableColumnBorderHorizontal,
        enableCellBorderVertical: themeConfig.tableEnableCellBorderVertical,
        enableCellBorderHorizontal: themeConfig.tableEnableCellBorderHorizontal,
        borderColor: themeConfig.tableBorderColor,
        cellUnselectedColor: Colors.transparent,
        evenRowColor: themeConfig.tableEvenRowColor ?? Colors.transparent,
        rowColor: themeConfig.tableOddRowColor ?? Colors.transparent,
        gridBorderColor: Colors.transparent,
        columnTextStyle: themeConfig.tableColumnTextStyle ?? TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
        gridBackgroundColor: themeConfig.tableGridBackgroundColor ?? Colors.transparent,
        cellTextStyle: themeConfig.tableCellTextStyle ?? TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 14,
        ),
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

  /// Build empty state widget for when table has no rows
  Widget _buildEmptyStateWidget(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 40,
                color: colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Nessun elemento',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Non ci sono dati da visualizzare',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Helper method to build icon button with tooltip
  Widget _buildIconButtonWithTooltip({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  /// Show column settings dialog
  void _showColumnSettings(BuildContext context, CrudoTableContext<TResource, TModel> tableContext) {
    showDialog(
      context: context,
      builder: (context) => CrudoTableSettingsPopup(
        settingsController: tableContext.settingsController,
      ),
    );
  }

  /// Build filters button with badge indicator
  Widget _buildFiltersButton(BuildContext context, CrudoTableContext<TResource, TModel> tableContext) {
    return BlocBuilder<CrudoTableBloc, CrudoTableState>(
      builder: (context, state) {
        final filters = tableContext.getFiltersData();
        final activeCount = filters.entries
            .where((e) => e.value != null && e.value.toString().isNotEmpty)
            .length;

        return Stack(
          children: [
            _buildIconButtonWithTooltip(
              context: context,
              icon: Icons.filter_alt_outlined,
              tooltip: 'Filtri',
              onPressed: () => _showFiltersPopup(context, tableContext),
            ),
            if (activeCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$activeCount',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Show filters popup
  void _showFiltersPopup(BuildContext context, CrudoTableContext<TResource, TModel> tableContext) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return CrudoTableFiltersPopup<TResource, TModel>(
          tableContext: tableContext,
          filtersFormBuilder: filtersFormBuilder!,
        );
      },
    );
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
            : Tooltip(
                message: action.label,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _onCreateClicked(context);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        action.icon,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
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
