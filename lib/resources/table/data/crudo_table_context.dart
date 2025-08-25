import 'package:crud_o_core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o_core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:crud_o/resources/table/data/controllers/crudo_table_settings_controller.dart';
import 'package:crud_o/resources/table/data/models/crudo_table_filter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  Map<String, dynamic> _activeFiltersData = {};

  CrudoTableContext(
      {required this.initialTableFuture, required this.resource}) {
    _currentTableFuture = initialTableFuture;
  }

  Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)
      getTableFuture() => _currentTableFuture;

  /// Reload the table by resetting any filters, sorting and pagination
  /// This is like user navigating to the page for the first time
  void reloadTable() {
    bloc.add(LoadTableEvent());
  }

  /// Refresh the table by keeping the current filters, sorting and pagination
  /// This just requests the same data again to the server
  void refreshTable() {
    if (bloc.state is TableLoadedState) {
      bloc.add(
          UpdateTableEvent(request: (bloc.state as TableLoadedState).request));
    }
  }

  /// Update the table with new parameters
  void updateTable(PaginatedRequest request) {
    bloc.add(UpdateTableEvent(request: request));
  }

  /// Format filters for query parameters
  Map<String,String> formatFiltersForQuery(Map<String, dynamic> filtersData) {
    // Format from <String,dynamic> to <String,String>
    Map<String, String> formattedFilters = {};
    for (var key in filtersData.keys) {

      // Skip if null
      if (filtersData[key] == null) continue;

      // If datetime and time is 00:00:00, remove it
      if (filtersData[key] is DateTime) {
        var date = filtersData[key] as DateTime;
        if (date.hour == 0 && date.minute == 0 && date.second == 0) {
          formattedFilters[key] = DateFormat('yyyy-MM-DD').format(date);
          continue;
        }
      }

      formattedFilters[key] = filtersData[key].toString();
    }
    return formattedFilters;
  }

  /// Set the filters of the table from the popup
  void setFilters(Map<String, dynamic> filtersData) {
    // Save the filters
    _activeFiltersData = filtersData;

    bloc.add(UpdateTableEvent(
        request: PaginatedRequest(queryParameters: formatFiltersForQuery(filtersData), page: 1)));
  }

  /// Get the filters that are currently active
  Map<String, dynamic> getFiltersData() => _activeFiltersData;

  /// Get a specific filter value
  T getFilterValue<T>(String filterName) {
    return _activeFiltersData[filterName] as T;
  }

// /// Check if a filter is active
// bool isFilterActive(CrudoTableFilter<TModel> filter) {
//   return _activeFilters.contains(filter.name);
// }
}

extension TableContextExtension on BuildContext {
  CrudoTableContext<TResource, TModel>
      readTableContext<TResource extends CrudoResource<TModel>, TModel>() =>
          read<CrudoTableContext<TResource, TModel>>();
}
