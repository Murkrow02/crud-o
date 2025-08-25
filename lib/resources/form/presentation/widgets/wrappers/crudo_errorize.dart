import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/crudo_field_entry.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:flutter/material.dart';

class CrudoErrorize extends StatelessWidget {
  final Widget child;
  final CrudoFieldConfiguration config;
  const CrudoErrorize({super.key, required this.child, required this.config});

  @override
  Widget build(BuildContext context) {
    var error = context.readFormContext().validationErrors[config.name]?.first;
    if (error == null || error!.isEmpty) {
      return child;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        child,
        Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
          child: Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
