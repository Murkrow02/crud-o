import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';

/*
*   A field that repeats n times a child form
*   The value of this field is how many items are added
*   The value is null if no items are added
*/
class CrudoRepeaterField extends StatefulWidget {
  final CrudoFieldConfiguration config;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int initialItemCount;
  final bool autoFlattenData;
  final CrudoRepeaterController? controller;

  const CrudoRepeaterField({
    super.key,
    required this.config,
    required this.itemBuilder,
    this.initialItemCount = 1,
    this.autoFlattenData = true,
    this.controller,
  });

  @override
  _CrudoRepeaterFieldState createState() => _CrudoRepeaterFieldState();
}

class _CrudoRepeaterFieldState extends State<CrudoRepeaterField> {
  int _itemsCount = 0;

  @override
  void initState() {
    super.initState();

    // Bind controller to this state if provided
    widget.controller?.bind(this);

    // Initialize the repeater with the initial item count
    _itemsCount = context.readResourceContext().getCurrentOperationType() ==
        ResourceOperationType.view
        ? 0
        : widget.initialItemCount;
  }

  @override
  Widget build(BuildContext context) {
    var alreadyFlattened = context.readFormContext().get(
        '${widget.config.name}_flattened'); // Temp logic to flatten data

    if ((widget.autoFlattenData && alreadyFlattened == null) ||
        !alreadyFlattened) {
      var flattenedData = _autoFlattenData();
      flattenedData.forEach((key, value) {
        context.readFormContext().set(key, value);
      });
      context.readFormContext().set('${widget.config.name}_flattened', true);
    }

    return CrudoField(
      config: widget.config.copyWith(name: '${widget.config.name}_count'),
      viewModeBuilder: (context) =>
          CrudoViewField(config: widget.config, child: _buildRepeaterItems(context)),
      editModeBuilder: (context, onChanged) => Padding(
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
              _buildRepeaterItems(context),
              const SizedBox(height: 8),
              IconButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary),
                ),
                onPressed: () => _addRepeaterItem(),
                icon: Icon(Icons.add,
                    color: Theme.of(context).colorScheme.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepeaterItems(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _itemsCount,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
          dense: true,
          title: widget.itemBuilder(context, index),
          trailing: SizedBox(
            width: 25,
            height: 25,
            child: Visibility(
              visible:
              context.readResourceContext().getCurrentOperationType() !=
                  ResourceOperationType.view,
              child: IconButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.error),
                ),
                onPressed: () => _removeRepeaterItem(index),
                icon: Icon(Icons.remove,
                    size: 10, color: Theme.of(context).colorScheme.onError),
              ),
            ),
          ),
        );
      },
    );
  }

  void _addRepeaterItem() {
    setState(() {
      _itemsCount++;
    });
  }

  void _removeRepeaterItem(int index) {
    var searchKey = '${widget.config.name}[$index].';
    var keysToRemove = context
        .readFormContext()
        .getFormData()
        .keys
        .where((key) => key.startsWith(searchKey))
        .toList();

    for (var key in keysToRemove) {
      context.readFormContext().unset(key);
    }

    for (int i = index + 1; i < _itemsCount; i++) {
      var oldKeyPrefix = '${widget.config.name}[$i].';
      var newKeyPrefix = '${widget.config.name}[${i - 1}].';

      var keysToUpdate = context
          .readFormContext()
          .getFormData()
          .keys
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

  Map<String, dynamic> _autoFlattenData() {
    var key = widget.config.name;
    var items = context.readFormContext().get(key);

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
            flatten(listItem, newKey);
          } else {
            flattenedData[newKey] = listItem;
          }
        }
      } else if (value is Map<String, dynamic>) {
        value.forEach((key, mapValue) {
          var newKey = '$currentKey.$key';
          flatten(mapValue, newKey);
        });
      } else {
        flattenedData[currentKey] = value;
      }
    }

    flatten(items, key);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _itemsCount = items.length;
      });
    });

    return flattenedData;
  }
}



class CrudoRepeaterController {
  _CrudoRepeaterFieldState? _state;

  /// Binds the controller to the repeater field's state
  void bind(_CrudoRepeaterFieldState state) {
    _state = state;
  }

  /// Adds a new item to the repeater
  void addItem() {
    _state?._addRepeaterItem();
  }

  /// Removes an item at the specified index
  void removeItem(int index) {
    _state?._removeRepeaterItem(index);
  }

  /// Retrieves the current count of items
  int get itemCount => _state?._itemsCount ?? 0;
}


