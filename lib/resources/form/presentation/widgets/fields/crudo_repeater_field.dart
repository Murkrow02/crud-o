import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'crudo_field.dart';

/*
*   A field that repeats n times a child form
*   The value of this field is how many items are added
*   The value is null if no items are added
*/
class CrudoRepeaterField extends StatefulWidget {
  final CrudoFieldConfiguration config;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int initialItemCount;

  /// If true, the data will be automatically flattened to a single level
  /// This converts data from <Key, <Key, Value>> -> key[index].key: value
  final bool autoFlattenData;

  const CrudoRepeaterField({
    super.key,
    required this.config,
    required this.itemBuilder,
    this.initialItemCount = 1,
    this.autoFlattenData = true,
  });

  @override
  _CrudoRepeaterFieldState createState() => _CrudoRepeaterFieldState();
}

class _CrudoRepeaterFieldState extends State<CrudoRepeaterField> {
  List<int> _items = [];

  @override
  void initState() {
    super.initState();
    // Initialize the repeater with the initial item count
    _items = List.generate(widget.initialItemCount, (index) => index);
    updateFieldValue();

    // If autoFlattenData is enabled, flatten the data
    if (widget.autoFlattenData) {
      _autoFlattenData();
    }
  }

  /// This updates the value of the repeater field in order to help validation
  /// When the field is required but empty, the form will show an error
  void updateFieldValue() {
    context.readFormContext().set('${widget.config.name}_count',
        _items.isNotEmpty ? _items.length : null);
  }

  @override
  Widget build(BuildContext context) {
    // Check if we should render a preview
    if (widget.config.shouldRenderViewField(context)) {
      return CrudoViewField(
        name: widget.config.label ?? widget.config.name,
        child: Text(
            context.readFormContext().get(widget.config.name)?.toString() ??
                ''),
      );
    }

    // Edit or create mode
    return FormBuilderField(
      validator:
          widget.config.required ? FormBuilderValidators.required(errorText: TempLang.requiredField) : null,
      name: '${widget.config.name}_count',
      builder: (FormFieldState<dynamic> field) {
        return CrudoFieldWrapper(
          config: widget.config.copyWith(
            name: '${widget.config.name}_count',
          ),
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    children: [
                      ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: widget.itemBuilder(context, index),
                              trailing: SizedBox(
                                width: 25,
                                height: 25,
                                child: IconButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all(
                                        Theme.of(context).colorScheme.error),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _items.removeAt(index);
                                      updateFieldValue();
                                    });
                                  },
                                  icon: Icon(Icons.remove,
                                      size: 10,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onError),
                                ),
                              ),
                            );
                          }),
                      const SizedBox(height: 8),
                      IconButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                                Theme.of(context).colorScheme.primary),
                          ),
                          onPressed: () {
                            setState(() {
                              _items.add(_items.length);
                              updateFieldValue();
                            });
                          },
                          icon: Icon(Icons.add,
                              color: Theme.of(context).colorScheme.onPrimary)),
                    ],
                  ))),
        );
      },
    );
  }

  /// This methods automatically converts data from <Key, <Key, Value>> -> key[index].key: value
  void _autoFlattenData() {
    var formData = context.readFormContext().formData;
    var key = widget.config.name;
    var items = formData[key];
    if (items == null || items is! List || items.isEmpty) {
      return;
    }

    var flattenedData = <String, dynamic>{};
    void flatten(dynamic value, String currentKey) {
      if (value is List) {
        for (var i = 0; i < value.length; i++) {
          var listItem = value[i];
          var newKey = '$currentKey[$i]';

          if (listItem is Map<String, dynamic>) {
            // If the list item is a map, further flatten it
            flatten(listItem, newKey);
          } else {
            // Otherwise, assign the value directly (list of single values)
            flattenedData[newKey] = listItem;
          }
        }
      } else if (value is Map<String, dynamic>) {
        value.forEach((key, mapValue) {
          var newKey = '$currentKey.$key';
          flatten(mapValue, newKey);
        });
      } else {
        // If it's a primitive value, assign it directly
        flattenedData[currentKey] = value;
      }
    }

    // Start flattening from the root
    flatten(items, key);

    // Update the form data with the flattened data
    formData.addAll(flattenedData);

    // Update repeater items count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _items = List.generate(items.length, (index) => index);
      });
    });
  }
}
