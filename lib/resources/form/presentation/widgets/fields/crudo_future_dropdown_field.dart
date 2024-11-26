import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:collection/collection.dart';
import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';

class CrudoFutureDropdownField<TModel, TValue> extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final String errorText;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;
  final bool multiple;
  final bool nullable;
  final Future<List<TModel>> Function() futureProvider;
  final Future<List<TModel>> Function(String)? searchFuture;
  final String? searchHintText;
  final int minSearchLength;
  final bool retry;
  final Function(TModel? item)? onSelected;

  const CrudoFutureDropdownField(
      {super.key,
      required this.config,
      required this.itemBuilder,
      required this.valueBuilder,
      required this.futureProvider,
      this.searchFuture,
      this.searchHintText,
      this.minSearchLength = 1,
      this.multiple = false,
      this.nullable = false,
      this.retry = true,
      this.errorText = 'Errore nel caricamento dei dati',
      this.onSelected});

  @override
  Widget build(BuildContext context) {
    // Clear data if we got a new future
    _clearDataIfNewFuture(context);

    // Detect if edit or create
    if (config.shouldRenderViewField(context)) {
      return _buildPreviewField(context);
    }

    return CrudoFieldWrapper(
        config: config,
        child: Builder(builder: (context) {
          return _buildEditField(context);
        }));
  }

  Widget _buildPreviewField(BuildContext context) {
    return Futuristic<List<TModel>>(
      autoStart: true,
      futureBuilder: () => futureProvider(),
      errorBuilder: (context, error, retry) =>
          _buildError(context, error, retry),
      dataBuilder: (context, data) {
        var initialItem = getInitialItem(context, data ?? []);
        return CrudoViewField(
          config: config,
          child:
              initialItem != null ? itemBuilder(initialItem) : const Text(''),
        );
      },
    );
  }

  Widget _buildEditField(BuildContext context) {
    return Futuristic<List<TModel>>(
      autoStart: true,
      futureBuilder: () => futureProvider(),
      busyBuilder: (context) => _buildDropdown([], context, loading: true),
      errorBuilder: (context, error, retry) =>
          _buildError(context, error, retry),
      dataBuilder: (context, data) => _buildDropdown(data ?? [], context),
    );
  }

  Widget _buildError(BuildContext context, dynamic error, VoidCallback retry) {
    if (kDebugMode) {
      print(error);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      color: Theme.of(context).colorScheme.error.withOpacity(0.4),
      child: Column(
        children: [
          Text(errorText),
          const SizedBox(height: 8),
          if (this.retry)
            ElevatedButton(
              onPressed: retry,
              child: const Text('Riprova'),
            ),
        ],
      ),
    );
  }

  TModel? getInitialItem(BuildContext context, List<TModel> items) {
    var value = context.readFormContext().get(config.name)
        as TValue?; // Get the value from the form
    if (value == null || items.isEmpty) {
      return null;
    }
    var item = items.firstWhereOrNull(
        (el) => valueBuilder(el).toString() == value.toString());
    return item;
  }

  Widget _buildDropdown(List<TModel> items, BuildContext context,
      {bool loading = false}) {
    if (multiple) {
      throw UnimplementedError('Multiple selection not implemented yet');
    }

    // At first use the data from the future, then use the data from the form in case devs wants to dynamically change the items
    if (context.readFormContext().getDropdownData(config.name) == null &&
        items.isNotEmpty) {
      context.readFormContext().setDropdownData(config.name, items);
    } else if (context.readFormContext().getDropdownData(config.name) != null) {
      items =
          context.readFormContext().getDropdownData<TModel>(config.name) ?? [];
    }

    // Little placeholder for lazy loading display
    if (loading) {
      return TextField(
        enabled: false,
        decoration: defaultDecoration.copyWith(
          hintText: 'Caricamento...',
        ),
      );
    }

    // Decide whether to use `.searchRequest` or the regular constructor
    bool useSearchRequest = true; // Or set the condition based on your logic
    return _buildCustomDropdown(
      items: items,
      context: context,
      config: config,
      initialItem: getInitialItem(context, items),
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      enabled: config.enabled,
    );
  }

  void _handleDropdownChange(
      BuildContext context,
      CrudoFieldConfiguration config,
      TModel? value,
      void Function(TModel?)? onSelected) {
    var valueToSet = value != null ? valueBuilder(value) : null;
    context.readFormContext().set(config.name, valueToSet);
    if (config.reactive) {
      context.readFormContext().rebuild();
    }
    onSelected?.call(value);
  }

  Widget _buildCustomDropdown({
    required List<TModel> items,
    required BuildContext context,
    required CrudoFieldConfiguration config,
    required TModel? initialItem,
    required Widget Function(TModel) itemBuilder,
    required void Function(TModel?)? onSelected,
    bool enabled = true,
  }) {
    return Row(
      children: [
        Expanded(
          child: Builder(
            builder: (context) {
              if (searchFuture != null) {
                return CustomDropdown<TModel>.searchRequest(
                  minSearchLength: minSearchLength,
                  searchHintText: searchHintText ?? 'Cerca...',
                  initialItem: initialItem,
                  enabled: config.enabled,
                  hintText: config.label,
                  items: items,
                  listItemBuilder: (context, item, isSelected, onItemSelect) =>
                      itemBuilder(item),
                  headerBuilder: (context, selectedItem, enabled) =>
                      initialItem != null
                          ? itemBuilder(initialItem)
                          : Text(config.label ?? config.name),
                  onChanged: (value) =>
                      _handleDropdownChange(context, config, value, onSelected),
                  futureRequest: (String searchText) =>
                      searchFuture!(searchText),
                );
              } else {
                return CustomDropdown<TModel>(
                  initialItem: initialItem,
                  enabled: config.enabled,
                  hintText: config.label,
                  items: items,
                  listItemBuilder: (context, item, isSelected, onItemSelect) =>
                      itemBuilder(item),
                  headerBuilder: (context, selectedItem, enabled) =>
                      initialItem != null
                          ? itemBuilder(initialItem)
                          : Text(config.label ?? config.name),
                  onChanged: (value) =>
                      _handleDropdownChange(context, config, value, onSelected),
                );
              }
            },
          ),
        ),
        Visibility(
          visible: nullable,
          child: SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                context.readFormContext().set(config.name, null);
                context.readFormContext().rebuild();
              },
            ),
          ),
        ),
      ],
    );
  }

  /// This checks if the future provider has changed and clears the data if so
  /// This is needed since user can manually change the dropdown data so we cant always rely on the future
  /// We take data from the future only the first time or if the future provider changes
  void _clearDataIfNewFuture(BuildContext context) {
    if (context.readFormContext().formDropdownFutureSignatures[config.name] !=
        futureProvider.hashCode) {
      context.readFormContext().formDropdownData.remove(config.name);
      context.readFormContext().formDropdownFutureSignatures[config.name] =
          futureProvider.hashCode;
    }
  }
}
