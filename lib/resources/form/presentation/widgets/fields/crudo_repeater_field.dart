import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'crudo_field.dart';
class CrudoRepeaterField extends StatefulWidget {
  final CrudoFieldConfiguration config;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final int initialItemCount;

  const CrudoRepeaterField({
    super.key,
    required this.config,
    required this.itemBuilder,
    this.initialItemCount = 1,
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
  }

  @override
  Widget build(BuildContext context) {
    // Check if we should render a preview
    if (widget.config.shouldRenderViewField(context)) {
      return CrudoViewField(
        name: widget.config.name,
        child: Text(context.readFormContext().get(widget.config.name)?.toString() ?? ''),
      );
    }

    // Edit or create mode
    return CrudoFieldWrapper(
      config: widget.config,
      child: Column(
        children: [
          // Render the list of items using itemBuilder
          ..._items.map((index) => widget.itemBuilder(context, index)).toList(),
          const SizedBox(height: 8),
          // Button to add a new field
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items.add(_items.length);
              });
            },
            child: const Text('Add Item'),
          ),
          // Button to remove the last field
          if (_items.isNotEmpty)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _items.removeLast();
                });
              },
              child: const Text('Remove Last Item'),
            ),
        ],
      ),
    );
  }
}
