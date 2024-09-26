import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:collection/collection.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:futuristic/futuristic.dart';
import 'package:provider/provider.dart';

class FormBuilderFutureDropdown<TModel, TValue> extends StatelessWidget {
  final String name;
  final String errorText;
  final InputDecoration decoration;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;
  final bool multiple;
  final Future<List<TModel>> future;
  final Function(TModel? item)? onSelected;
  const FormBuilderFutureDropdown({
    super.key,
    required this.itemBuilder,
    required this.name,
    required this.valueBuilder,
    required this.future,
    this.decoration = const InputDecoration(),
    this.multiple = false,
    this.errorText = 'Errore nel caricamento dei dati',
    this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<dynamic>(
      name: name,
      builder: (FormFieldState<dynamic> field) {
        return Futuristic<List<TModel>>(
          autoStart: true,
          futureBuilder: ()=> future,
          busyBuilder: (context) =>
              _buildDropdown([], context, field, enabled: false),
          errorBuilder: (context, error, retry) {
            print(error);
            return Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).colorScheme.error.withOpacity(0.4),
            child: Column(
              children: [
                Text(errorText),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: retry,
                  child: const Text('Riprova'),
                ),
              ],
            ),
          );
          },
          dataBuilder: (context, data) =>
              _buildDropdown(data ?? [], context, field),
        );
      },
    );
  }

  Widget _buildDropdown(
      List<TModel> items, BuildContext context, FormFieldState<dynamic> field,
      {bool enabled = true}) {
    var hintText = decoration.labelText;
    listItemBuilder(context, item, isSelected, onItemSelect) {
      return itemBuilder(item);
    }

    if (multiple) {

      var initialItems = field.value == null
          ? []
          : items.where((el) {
        var value = valueBuilder(el);
        return field.value.contains(value);
      }).toList();

      return CustomDropdown<TModel>.multiSelect(
        hintText: hintText,
        items: items,
        listItemBuilder: listItemBuilder,
        //initialItems: initialItems,
        headerListBuilder: (context, selectedItems, enabled) {
          return Wrap(
            spacing: 5,
            children: selectedItems.map((el) => itemBuilder(el)).toList(),
          );
        },
        onListChanged: (List<TModel> items) {
          field.didChange(items.map(valueBuilder).toList());
        },
      );
    }

    return CustomDropdown<TModel>(
      hintText: hintText,
      items: items,
      listItemBuilder: listItemBuilder,

      // Auto select item only if passed value is not null, we have some items and the field is enabled
      initialItem: (field.value == null || !enabled || items.isEmpty)
          ? null
          : items.firstWhereOrNull(
              (el) => valueBuilder(el).toString() == field.value.toString()),

      headerBuilder: (context, selectedItem, enabled) {
        return selectedItem != null
            ? itemBuilder(selectedItem)
            : Text(hintText ?? 'Select an item');
      },
      onChanged: (value) {
        if (value != null) {
          field.didChange(valueBuilder(value));
        }
        onSelected?.call(value);
      },
    );
  }
}
