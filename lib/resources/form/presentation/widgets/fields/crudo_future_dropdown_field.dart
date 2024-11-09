import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:collection/collection.dart';
import 'package:crud_o/actions/crudo_action.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/data/form_result.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_extra_fields/form_builder_extra_fields.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:futuristic/futuristic.dart';
import 'package:provider/provider.dart';

class CrudoFutureDropdownField<TModel, TValue> extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final String errorText;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;
  final bool multiple;
  final bool nullable;
  final Future<List<TModel>> Function() futureProvider;
  final Future<List<TModel>> Function(String)? searchFuture;
  final bool retry;
  final Function(TModel? item)? onSelected;

  const CrudoFutureDropdownField({super.key,
    required this.config,
    required this.itemBuilder,
    required this.valueBuilder,
    required this.futureProvider,
    this.searchFuture,
    this.multiple = false,
    this.nullable = false,
    this.retry = true,
    this.errorText = 'Errore nel caricamento dei dati',
    this.onSelected});

  @override
  Widget build(BuildContext context) {
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
          name: config.label ?? config.name,
          child:
          initialItem != null ? itemBuilder(initialItem) : const Text(''),
        );
      },
    );
  }

  Widget _buildEditField(BuildContext context) {
    return FormBuilderField(
      name: config.name,
      validator: FormBuilderValidators.compose([
        if (config.required) FormBuilderValidators.required(),
      ]),
      builder: (FormFieldState<dynamic> field) {
        return Futuristic<List<TModel>>(
          autoStart: true,
          futureBuilder: () => futureProvider(),
          busyBuilder: (context) =>
              _buildDropdown([], context, field, loading: true),
          errorBuilder: (context, error, retry) =>
              _buildError(context, error, retry),
          dataBuilder: (context, data) =>
              _buildDropdown(data ?? [], context, field),
        );
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
      color: Theme
          .of(context)
          .colorScheme
          .error
          .withOpacity(0.4),
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
    var value = context
        .readFormContext()
        .get(config.name) as TValue?; // Get the value from the form
    if (value == null || items.isEmpty) {
      return null;
    }
    return items.firstWhereOrNull(
            (el) => valueBuilder(el).toString() == value.toString());
  }

  Widget _buildDropdown(List<TModel> items, BuildContext context,
      FormFieldState<dynamic> field,
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
      field: field,
      config: config,
      initialItem: getInitialItem(context, items),
      itemBuilder: itemBuilder,
      onSelected: onSelected,
      enabled: config.enabled,
    );
  }

  Widget _buildCustomDropdown({
    required List<TModel> items,
    required BuildContext context,
    required FormFieldState<dynamic> field,
    required CrudoFieldConfiguration config,
    required TModel? initialItem,
    required Widget Function(TModel) itemBuilder,
    required void Function(TModel?)? onSelected,
    bool enabled = true,
  }) {
    return Row(children: [
      Expanded(child:
      Builder(builder: (context) {
        if (searchFuture != null) {
          // Using the searchRequest constructor
          return CustomDropdown<TModel>.searchRequest(
            initialItem: initialItem,
            enabled: config.enabled,
            hintText: config.label,
            items: items,
            listItemBuilder: (context, item, isSelected, onItemSelect) {
              return itemBuilder(item);
            },
            headerBuilder: (context, selectedItem, enabled) {
              return initialItem != null
                  ? itemBuilder(initialItem)
                  : Text(config.label ?? config.name);
            },
            onChanged: (value) {
              context.readFormContext().set(
                  config.name, value != null ? valueBuilder(value) : null);
              context.readFormContext().rebuild();
              onSelected?.call(value);
            },
            futureRequest: (String searchText) => searchFuture!(searchText),
          );
        } else {
          // Using the regular constructor
          return CustomDropdown<TModel>(
            initialItem: initialItem,
            enabled: config.enabled,
            hintText: config.label,
            items: items,
            listItemBuilder: (context, item, isSelected, onItemSelect) {
              return itemBuilder(item);
            },
            headerBuilder: (context, selectedItem, enabled) {
              return initialItem != null
                  ? itemBuilder(initialItem)
                  : Text(config.label ?? config.name);
            },
            onChanged: (value) {
              context.readFormContext().set(
                  config.name, value != null ? valueBuilder(value) : null);
              context.readFormContext().rebuild();
              onSelected?.call(value);
            },
          );
        }
      })),
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
    ]);
  }
}
