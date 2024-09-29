import 'package:crud_o/resources/form/data/form_context_container.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'crudo_field.dart';

class CrudoRelationshipField extends StatelessWidget {

  final CrudoFieldConfiguration config;
  const CrudoRelationshipField({
    super.key,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {

    if (!config.shouldRenderField(context)) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Builder(builder: (context) {

        // Detect if preview
        if(config.shouldRenderViewField(context)) {
          return config.renderViewField(context);
        }

        return Text("ASD");

      }),
    );
  }


}

