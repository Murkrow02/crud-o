import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:collection/collection.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
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
  final Future<List<TModel>> Function() futureProvider;
  final bool retry;
  final Function(TModel? item)? onSelected;

  const CrudoFutureDropdownField(
      {super.key,
      required this.config,
      required this.itemBuilder,
      required this.valueBuilder,
      required this.futureProvider,
      this.multiple = false,
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
              _buildDropdown([], context, field, enabled: false),
          errorBuilder: (context, error, retry) =>
              _buildError(context, error, retry),
          dataBuilder: (context, data) =>
              _buildDropdown(data ?? [], context, field),
        );
      },
    );
  }

  Widget _buildError(BuildContext context, dynamic error, VoidCallback retry) {
    print(error);
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
    var value = context
        .readFormContext()
        .formKey
        .currentState
        ?.initialValue[config.name];
    if (value == null || items.isEmpty) {
      return null;
    }
    return items.firstWhereOrNull(
        (el) => valueBuilder(el).toString() == value.toString());
  }

  Widget _buildDropdown(
      List<TModel> items, BuildContext context, FormFieldState<dynamic> field,
      {bool enabled = true}) {
    if (multiple)
      throw UnimplementedError('Multiple selection not implemented yet');

    return CustomDropdown<TModel>(
      enabled: config.enabled,
      hintText: config.label,
      items: items,
      listItemBuilder: (context, item, isSelected, onItemSelect) {
        return itemBuilder(item);
      },
      initialItem: enabled ? getInitialItem(context, items) : null,
      headerBuilder: (context, selectedItem, enabled) {
        return selectedItem != null
            ? itemBuilder(selectedItem)
            : Text(config.label ?? config.name);
      },
      onChanged: (value) {
        if (value != null) {
          field.didChange(valueBuilder(value));
        }

        // Rebuild the form to update based on the new value
        if (config.reactive) {
          context.readFormContext().rebuild();
        }
        onSelected?.call(value);
      },
    );
  }
}
