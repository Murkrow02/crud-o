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
        child: Text(
            context.readFormContext().get(widget.config.name)?.toString() ??
                ''),
      );
    }

    // Edit or create mode
    return CrudoFieldWrapper(
        config: widget.config,
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
                                  });
                                },
                                icon: Icon(Icons.remove,
                                    size: 10,
                                    color: Theme.of(context).colorScheme.onError),
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
                          });
                        },
                        icon: Icon(Icons.add,
                            color: Theme.of(context).colorScheme.onPrimary)),
                  ],
                ))));
  }
}
