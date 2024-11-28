import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/table/data/controllers/crudo_table_settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:provider/provider.dart';

class CrudoTableContext<TResource extends CrudoResource<TModel>, TModel> {

  /// The current future used throughout the table, it is a function that receives a [PaginatedRequest] and produces a [PaginatedResponse]
  Future<PaginatedResponse<TModel>> Function(PaginatedRequest request)
      tableFuture;

  // Used to control the table
  late PlutoGridStateManager tableManager;

  // Used to control table settings (CRUDO)
  late CrudoTableSettingsController settingsController;

  // The resource we are working with
  TResource resource;

  // We need to keep track of the first load to avoid calling onDataChanged
  bool firstLoad = true;

  CrudoTableContext({required this.tableFuture, required this.resource});
}

extension TableContextExtension on BuildContext {
  CrudoTableContext<TResource,TModel> readTableContext<TResource extends CrudoResource<TModel>, TModel>() => read<CrudoTableContext<TResource,TModel>>();
}
