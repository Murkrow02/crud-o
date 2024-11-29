import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:crud_o/resources/table/data/controllers/crudo_table_settings_controller.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_filter.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:provider/provider.dart';

class CrudoTableContext<TResource extends CrudoResource<TModel>, TModel> {

  /// The future used at first when table is loaded
  /// It is a function that receives a [PaginatedRequest] and produces a [PaginatedResponse]
  final Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)
      initialTableFuture;

  /// Like [initialTableFuture] but can be changed through the lifecycle of the table
  /// For example if a filter is applied
  late Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)
  _currentTableFuture;

  // Used to control the table
  late PlutoGridStateManager tableManager;

  /// Used to control table settings (CRUDO)
  late CrudoTableSettingsController settingsController;

  /// The resource we are working with
  TResource resource;

  /// We need to keep track of the first load to avoid calling onDataChanged
  bool firstLoad = true;

  /// The bloc that controls the table and its state
  late final CrudoTableBloc<TResource, TModel> bloc;

  /// The filters that are currently active
  List<String> _activeFilters = [];

  CrudoTableContext({required this.initialTableFuture, required this.resource}){
    _currentTableFuture = initialTableFuture;
  }

  Future<PaginatedResponse<TModel>> Function(PaginatedRequest request) getTableFuture() => _currentTableFuture;

  /// Reload the table by resetting any filters, sorting and pagination
  /// This is like user navigating to the page for the first time
  void reloadTable() {
    bloc.add(LoadTableEvent());
  }

  /// Refresh the table by keeping the current filters, sorting and pagination
  /// This just requests the same data again to the server
  void refreshTable() {
    if(bloc.state is TableLoadedState) {
      bloc.add(UpdateTableEvent(request: (bloc.state as TableLoadedState).request));
    }
  }

  /// Update the table with new parameters
  void updateTable(PaginatedRequest request) {
    bloc.add(UpdateTableEvent(request: request));
  }

  /// Toggle a filter
  void toggleFilter(CrudoTableFilter<TModel> filter) {

    // Reset original future
    _currentTableFuture = initialTableFuture;

    // Filter needs to be removed
    if(_activeFilters.contains(filter.name)) {

      _activeFilters.remove(filter.name);

      // TODO for now just resets the table but should fallback with other filters
      if(filter.filterFunction != null) {
        bloc.add(LoadTableEvent());
      } else {
        bloc.add(LoadTableEvent());
      }


    }

    // Filter applied
    else {
      _activeFilters.add(filter.name);

      // Provided with a whole custom function
      if(filter.filterFunction != null) {
        _currentTableFuture = filter.filterFunction!;
        bloc.add(LoadTableEvent());
      }
      // Provided with just a request
      else {
        // Call the table with the new request
        bloc.add(UpdateTableEvent(request: filter.filterRequest!));
      }
    }


  }

  /// Check if a filter is active
  bool isFilterActive(CrudoTableFilter<TModel> filter) {
    return _activeFilters.contains(filter.name);
  }
}

extension TableContextExtension on BuildContext {
  CrudoTableContext<TResource,TModel> readTableContext<TResource extends CrudoResource<TModel>, TModel>() => read<CrudoTableContext<TResource,TModel>>();
}
