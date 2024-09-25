import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:futuristic/futuristic.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

class FormBuilderRelationship<TResource extends CrudoResource<TModel>, TModel, TValue>
    extends StatelessWidget {
  final String name;
  final InputDecoration decoration;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;
  final bool multiple;

  const FormBuilderRelationship({
    super.key,
    required this.itemBuilder,
    required this.name,
    required this.valueBuilder,
    this.decoration = const InputDecoration(),
    this.multiple = false,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<dynamic>(
      name: name,
      builder: (FormFieldState<dynamic> field) {
        return Futuristic<List<TModel>>(
          autoStart: true,
          futureBuilder: () => context.read<TResource>().repository.getAll(),
          busyBuilder: (context) =>
              _buildDropdown([], context, field, enabled: false),
          errorBuilder: (context, error, retry) => Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Theme.of(context).colorScheme.error.withOpacity(0.4),
            child: Column(
              children: [
                Text(
                    'Non è stato possibile caricare ${context.read<TResource>().pluralName()}'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: retry,
                  child: const Text('Riprova'),
                ),
              ],
            ),
          ),
          dataBuilder: (context, data) =>
              _buildDropdown(data ?? [], context, field),
        );
      },
    );
  }

  Widget _buildDropdown(
      List<TModel> items, BuildContext context, FormFieldState<dynamic> field,
      {bool enabled = true}) {

    // Create common values here to share between single and multiple dropdowns
    var hintText = decoration.labelText;
    listItemBuilder(context, item, isSelected, onItemSelect) {
      return itemBuilder(item);
    }

    if(multiple)
      {
        var initialItems = [];
        if (field.value != null) {
          var values = field.value;
          for (var value in values) {
            var found = items.firstWhere((el) => valueBuilder(el).toString() == value);
            if (found != null) {
              initialItems.add(found);
            }
          }
        }

        return CustomDropdown<TModel>.multiSelect(
          hintText: hintText,
          items: items,
          listItemBuilder:listItemBuilder,
          initialItems: field.value == null
              ? null
              : items.where((el) => field.value.contains(valueBuilder(el).toString())).toList(),
          headerListBuilder: (context, selectedItems, enabled) {
            return Wrap(
              spacing: 5,
              children: selectedItems.map((el) => itemBuilder(el)).toList()
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
      initialItem: (field.value == null || !enabled)
          ? null
          : items.firstWhere((el) => valueBuilder(el) == field.value),
      headerBuilder: (context, selectedItem, enabled) {
        return itemBuilder(selectedItem);
      },
      onChanged: (value) {
        if (value == null) {
          return;
        }
        field.didChange(valueBuilder(value));
      },
    );
  }
}
