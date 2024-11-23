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
  int _itemsCount = 0;

  @override
  void initState() {
    super.initState();
    // Initialize the repeater with the initial item count
    _itemsCount = widget.initialItemCount;
  }

  @override
  Widget build(BuildContext context) {

    var alreadyFlattened = context.readFormContext().get('${widget.config.name}_flattened'); // This is pure shit, change when possible to keep form data clean
    if (widget.autoFlattenData && alreadyFlattened == null || !alreadyFlattened) {
      var flattenedData = _autoFlattenData();
      flattenedData.forEach((key, value) {
        context.readFormContext().set(key, value);
      });
      context.readFormContext().set('${widget.config.name}_flattened', true);
    }


    return AbsorbPointer(
      absorbing: widget.config.shouldRenderViewField(context),
      child: CrudoFieldWrapper(
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
                            itemCount: _itemsCount,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: widget.itemBuilder(context, index),
                                trailing: SizedBox(
                                  width: 25,
                                  height: 25,
                                  child: Visibility(
                                    visible: !widget.config.shouldRenderViewField(context),
                                    child: IconButton(
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all(
                                            Theme.of(context).colorScheme.error),
                                      ),
                                      onPressed: () => _removeRepeaterItem(index),
                                      icon: Icon(Icons.remove,
                                          size: 10,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onError),
                                    ),
                                  ),
                                ),
                              );
                            }),
                        const SizedBox(height: 8),
                        Visibility(
                          visible: !widget.config.shouldRenderViewField(context),
                          child: IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    Theme.of(context).colorScheme.primary),
                              ),
                              onPressed: () {
                                setState(() {
                                  _itemsCount++;
                                });
                              },
                              icon: Icon(Icons.add,
                                  color: Theme.of(context).colorScheme.onPrimary)),
                        ),
                      ],
                    ))),
      ),
    );
  }

  /// This method provides the functionality to remove an item from the repeater UI.
  /// It also removes the corresponding data from the form data map by finding all keys that match the pattern 'key[index].*'.
  /// After removal, it shifts subsequent items' keys to ensure the indices remain consistent.
  void _removeRepeaterItem(int index) {

    // Find all keys in form data that are in the form of 'key[index].*'
    var searchKey = '${widget.config.name}[$index].';
    var keysToRemove = context.readFormContext().getFormData().keys
        .where((key) => key.startsWith(searchKey))
        .toList();

    // Remove all values that match the pattern
    for (var key in keysToRemove) {
      context.readFormContext().unset(key);
    }

    // Shift the indices of subsequent items
    for (int i = index + 1; i < _itemsCount; i++) {
      var oldKeyPrefix = '${widget.config.name}[$i].';
      var newKeyPrefix = '${widget.config.name}[${i - 1}].';

      // Update all keys in formData that start with the oldKeyPrefix
      var keysToUpdate = context.readFormContext().getFormData().keys
          .where((key) => key.startsWith(oldKeyPrefix))
          .toList();

      for (var key in keysToUpdate) {
        var newKey = key.replaceFirst(oldKeyPrefix, newKeyPrefix);
        var oldValue = context.readFormContext().get(key);
        context.readFormContext().set(newKey, oldValue);
        context.readFormContext().unset(key);
      }
    }

    setState(() {
      _itemsCount--;
    });
  }


  /// This methods automatically converts data from <Key, <Key, Value>> -> key[index].key: value
  Map<String, dynamic> _autoFlattenData() {
    var key = widget.config.name;
    var items = context.readFormContext().get(key);

    // Remove original data
    context.readFormContext().unset(key);
    if (items == null || items is! List || items.isEmpty) {
      return {};
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

    // Update repeater items count
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _itemsCount = items.length;
      });
    });

    return flattenedData;
  }
}
