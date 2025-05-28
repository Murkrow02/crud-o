import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/requests/rest_request.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_future_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrudoResourceDropdownField<TResource extends CrudoResource<TModel>, TModel,
    TValue> extends StatelessWidget {

  /// Standard crud_o field configuration
  final CrudoFieldConfiguration config;

  /// A custom decoration for the dropdown
  final CustomDropdownDecoration decoration;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;

  /// An optional custom selected item
  /// If this is set, the dropdown will show this item as selected
  /// If this is not set, the dropdown will automatically retrieve the item from API
  final TModel? selectedItem;
  final String? searchHintText;
  final RestRequest? customRequest;
  final bool nullable;
  final int minSearchLength;

  const CrudoResourceDropdownField(
      {super.key,
      required this.config,
      required this.itemBuilder,
      required this.valueBuilder,
      this.selectedItem,
      this.nullable = false,
      this.searchHintText,
      this.minSearchLength = 1,
      this.customRequest,
      this.decoration = const CustomDropdownDecoration()});

  @override
  Widget build(BuildContext context) {
    return CrudoFutureDropdownField<TModel, TValue>(
      config: config,
      retry: false,
      itemBuilder: itemBuilder,
      valueBuilder: valueBuilder,
      nullable: nullable,
      searchHintText: searchHintText,
      decoration: decoration,
      minSearchLength: minSearchLength,
      futureProvider: () => _getDropdownItems(context),
      searchFuture: (String query) async {
        return context
            .read<TResource>()
            .repository
            .getAll(parameters: RestRequest(search: query));
      },
    );
  }

  Future<List<TModel>> _getDropdownItems(BuildContext context) async {
    // Retrieve the selected item (if any)
    var alreadySelectedId = context.readFormContext().get(config.name);

    // Access the repository and the form's cache
    var resourceRepository = context.read<TResource>().repository;
    var formContext = context.readFormContext();

    // Build a stable cache key for the getAll call
    final listCacheKey = resourceRepository.hashCode.toString() +
        (customRequest?.toQueryString() ?? '');

    // Check if an in-flight Future is already cached for the list
    Future<List<TModel>>? dropdownItemsFuture =
        formContext.getFutureCache<Future<List<TModel>>>(listCacheKey);

    // If not cached, initiate the API call and cache the Future immediately
    if (dropdownItemsFuture == null) {
      dropdownItemsFuture =
          resourceRepository.getAll(parameters: customRequest);
      formContext.setFutureCache(listCacheKey, dropdownItemsFuture);
    }

    // Await the cached Future to get the actual result
    var dropdownItems = await dropdownItemsFuture;

    // If there's no selected item, return the fetched items.
    if (alreadySelectedId == null) {
      return dropdownItems;
    }

    // Get the selected item and add it to the dropdown items
    var selectedItem = this.selectedItem ?? await _getSelectedItem(context, alreadySelectedId);

    // Remove any duplicate entry and add the selected item
    dropdownItems
      ..removeWhere((dynamic element) => element.id == alreadySelectedId)
      ..add(selectedItem);

    return dropdownItems;
  }

  Future<TModel> _getSelectedItem(BuildContext context, TValue alreadySelectedId) async
  {
    var resourceRepository = context.read<TResource>().repository;
    var formContext = context.readFormContext();

    // Build a separate cache key for the individual getById call
    final individualCacheKey =
        '${resourceRepository.hashCode}_$alreadySelectedId';

    Future<TModel>? individualFuture =
    formContext.getFutureCache<Future<TModel>>(individualCacheKey);

    if (individualFuture == null) {
      individualFuture =
          resourceRepository.getById(alreadySelectedId.toString());
      formContext.setFutureCache(individualCacheKey, individualFuture);
    }

    // Await the cached Future for the individual item
    var selectedItem = await individualFuture;

    return selectedItem;
  }
}
