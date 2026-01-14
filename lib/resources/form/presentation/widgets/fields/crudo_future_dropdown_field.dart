import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:collection/collection.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';


/// A styled dropdown field that loads items from a Future.
/// Supports search functionality and uses theme configuration for consistent styling.
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
  final CustomDropdownDecoration? decoration;

  const CrudoFutureDropdownField({
    super.key,
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
    this.decoration,
    this.errorText = 'Error loading data',
  });

  /// Creates a themed CustomDropdownDecoration based on theme configuration.
  CustomDropdownDecoration _getThemedDecoration(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    final fillColor = theme.dropdownBackgroundColor ??
        theme.fieldFillColor ??
        colorScheme.surface;
    final borderColor = theme.dropdownBorderColor ??
        theme.fieldBorderColor ??
        colorScheme.outline.withOpacity(0.3);
    final expandedBorderColor = theme.dropdownExpandedBorderColor ??
        theme.fieldFocusedBorderColor ??
        colorScheme.primary.withOpacity(0.6);

    return CustomDropdownDecoration(
      closedFillColor: fillColor,
      expandedFillColor: fillColor,
      closedBorder: Border.all(
        color: borderColor,
        width: theme.fieldBorderWidth,
      ),
      expandedBorder: Border.all(
        color: expandedBorderColor,
        width: theme.fieldFocusedBorderWidth,
      ),
      closedBorderRadius: BorderRadius.circular(theme.dropdownBorderRadius),
      expandedBorderRadius: BorderRadius.circular(theme.dropdownBorderRadius),
      closedSuffixIcon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: colorScheme.onSurface.withOpacity(0.5),
      ),
      expandedSuffixIcon: Icon(
        Icons.keyboard_arrow_up_rounded,
        color: colorScheme.primary,
      ),
      hintStyle: theme.fieldHintStyle ?? TextStyle(
        color: colorScheme.onSurface.withOpacity(0.4),
      ),
      listItemStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15,
      ),
      headerStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                : Text(
                    '—',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
          );
        }
      },
    );
  }

  Widget _buildError(BuildContext context, dynamic error, VoidCallback retry) {
    if (kDebugMode) {
      print(error);
    }

    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(theme.fieldBorderRadius),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: colorScheme.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  errorText,
                  style: TextStyle(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (this.retry) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: retry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  backgroundColor: colorScheme.error.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
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

    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    // Modern loading placeholder
    if (loading) {
      return Container(
        padding: theme.fieldContentPadding,
        decoration: BoxDecoration(
          color: theme.fieldFillColor ?? colorScheme.surface,
          borderRadius: BorderRadius.circular(theme.dropdownBorderRadius),
          border: Border.all(
            color: theme.fieldBorderColor ?? colorScheme.outline.withOpacity(0.3),
            width: theme.fieldBorderWidth,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading...',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

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

    final themedDecoration = decoration ?? _getThemedDecoration(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Builder(
            builder: (context) {
              if (searchFuture != null) {
                return CustomDropdown<TModel>.searchRequest(
                  decoration: themedDecoration,
                  minSearchLength: minSearchLength,
                  searchHintText: searchHintText ?? 'Search...',
                  initialItem: initialItem,
                  enabled: config.shouldEnableField(context),
                  hintText: config.placeholder ?? config.label,
                  items: items,
                  listItemBuilder: (context, item, isSelected, onItemSelect) =>
                      itemBuilder(item),
                  headerBuilder: (context, selectedItem, enabled) =>
                      initialItem != null
                          ? itemBuilder(initialItem)
                          : Text(
                              config.placeholder ?? config.label ?? config.name,
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
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
                  hintText: config.placeholder ?? config.label,
                  items: items,
                  decoration: themedDecoration,
                  listItemBuilder: (context, item, isSelected, onItemSelect) =>
                      itemBuilder(item),
                  headerBuilder: (context, selectedItem, enabled) =>
                      initialItem != null
                          ? itemBuilder(initialItem)
                          : Text(
                              config.placeholder ?? config.label ?? config.name,
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                  onChanged: (value) => _handleDropdownChange(
                      context, config, value,
                      notifyValueChanged: true),
                );
              }
            },
          ),
        ),
        if (nullable)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: IconButton(
              icon: Icon(
                Icons.clear_rounded,
                color: colorScheme.onSurface.withOpacity(0.4),
                size: 20,
              ),
              onPressed: () {
                context.readFormContext().set(config.name, null);
                context.readFormContext().rebuild();
              },
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
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
