import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:collection/collection.dart';
import 'package:crud_o_core/lang/temp_lang.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';

import 'crudo_fields.dart';

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
  final CustomDropdownDecoration decoration;

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
      this.decoration = const CustomDropdownDecoration(),
      this.errorText = 'Errore nel caricamento dei dati'});

  @override
  Widget build(BuildContext context) {
    // Clear data if we got a new future
    _clearDataIfNewFuture(context);

    return CrudoField(
      viewModeBuilder: (context) => _buildField(context, isEditMode: false),
      editModeBuilder: (context, onChanged) =>
          _buildField(context, isEditMode: true),
      config: config,
    );
  }

  Widget _buildField(BuildContext context, {required bool isEditMode}) {
    return Futuristic<List<TModel>>(
      autoStart: true,
      futureBuilder: () => futureProvider(),
      busyBuilder: isEditMode
          ? (context) => _buildDropdown([], context, loading: true)
          : null,
      errorBuilder: (context, error, retry) =>
          _buildError(context, error, retry),
      dataBuilder: (context, data) {
        // At first use the data from the future, then use the data from the form in case devs wants to dynamically change the items
        // It is important to set dropdown data also in the view mode if dev wants to take data from the form in the view mode
        if (context.readFormContext().getDropdownData(config.name) == null &&
            data!.isNotEmpty) {
          context.readFormContext().setDropdownData(config.name, data);
        } else if (context.readFormContext().getDropdownData(config.name) !=
            null) {
          data =
              context.readFormContext().getDropdownData<TModel>(config.name) ??
                  [];
        }

        if (isEditMode) {
          return _buildDropdown(data ?? [], context);
        } else {
          var initialItem = getInitialItem(context, data ?? []);
          return CrudoViewField(
            config: config,
            child: initialItem != null
                ? itemBuilder(initialItem)
                : const Text('N/A'),
          );
        }
      },
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
    // Check if actually something is selected
    var value = context.readFormContext().get<TValue?>(config.name);
    if (value == null || items.isEmpty) {
      return null;
    }

    // First check if the value is already in the items list
    var item = items.firstWhereOrNull(
        (el) => valueBuilder(el).toString() == value.toString());

    // Then maybe is the selected value that can also not be present in the list (accessed through search)
    if (item == null) {
      var selectedItem = context
          .readFormContext()
          .getDropdownSelectedValue<TModel?>(config.name);
      if (selectedItem != null &&
          valueBuilder(selectedItem).toString() == value.toString()) {
        item = selectedItem;
      }
    }

    return item;
  }

  Widget _buildDropdown(List<TModel> items, BuildContext context,
      {bool loading = false}) {
    if (multiple) {
      throw UnimplementedError('Multiple selection not implemented yet');
    }

    // Little placeholder for lazy loading display
    if (loading) {
      return TextField(
        enabled: false,
        decoration: defaultDecoration(context).copyWith(
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
        enabled: config.shouldEnableField(context));
  }

  void _handleDropdownChange(BuildContext context,
      CrudoFieldConfiguration config, TModel? selectedModel,
      {skipRebuild = false, notifyValueChanged = false}) {
    // Return if null
    if (selectedModel == null) {
      return;
    }

    // Add selected item in the form context extra
    context
        .readFormContext()
        .setDropdownSelectedValue(config.name, selectedModel);

    // Create value from the selected model
    var valueToSet = selectedModel != null ? valueBuilder(selectedModel) : null;
    context.readFormContext().set(config.name, valueToSet);

    // Only notify when manually changing the value
    if (notifyValueChanged) {
      config.onChanged?.call(context, valueToSet);
    }

    // Rebuild the form if needed
    if (!skipRebuild) {
      context.readFormContext().rebuild();
    }
  }

  Widget _buildCustomDropdown({
    required List<TModel> items,
    required BuildContext context,
    required CrudoFieldConfiguration config,
    required TModel? initialItem,
    required Widget Function(TModel) itemBuilder,
    bool enabled = true,
  }) {
    // Fire handleDropdownChange if the value is not in the items list
    _handleDropdownChange(context, config, initialItem, skipRebuild: true);
    return Row(
      children: [
        Expanded(
          child: Builder(
            builder: (context) {
              if (searchFuture != null) {
                return CustomDropdown<TModel>.searchRequest(
                  decoration: decoration,
                  minSearchLength: minSearchLength,
                  searchHintText: searchHintText ?? 'Cerca...',
                  initialItem: initialItem,
                  enabled: config.shouldEnableField(context),
                  hintText: config.label,
                  items: items,
                  listItemBuilder: (context, item, isSelected, onItemSelect) =>
                      itemBuilder(item),
                  headerBuilder: (context, selectedItem, enabled) =>
                      initialItem != null
                          ? itemBuilder(initialItem)
                          : Text(config.label ?? config.name),
                  onChanged: (value) => _handleDropdownChange(
                      context, config, value,
                      notifyValueChanged: true),
                  futureRequest: (String searchText) =>
                      searchFuture!(searchText),
                );
              } else {
                return CustomDropdown<TModel>(
                  initialItem: initialItem,
                  enabled: config.shouldEnableField(context),
                  hintText: config.label,
                  items: items,
                  decoration: decoration,
                  listItemBuilder: (context, item, isSelected, onItemSelect) =>
                      itemBuilder(item),
                  headerBuilder: (context, selectedItem, enabled) =>
                      initialItem != null
                          ? itemBuilder(initialItem)
                          : Text(config.label ?? config.name),
                  onChanged: (value) => _handleDropdownChange(
                      context, config, value,
                      notifyValueChanged: true),
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
    var fc = context.readFormContext();
    if (fc.getDropdownFutureSignature(config.name) != futureProvider.hashCode) {
      fc.removeDropdownData(config.name);
      fc.setDropdownFutureSignature(config.name, futureProvider.hashCode);
    }
  }
}
