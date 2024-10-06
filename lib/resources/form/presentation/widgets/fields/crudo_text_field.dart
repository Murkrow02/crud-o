import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'crudo_field.dart';

class CrudoTextField extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final TextInputType keyboardType;
  final ValueTransformer<String?>? valueTransformer;
  final FormFieldValidator<String>? validator;
  final bool numeric;
  final int maxLines;

  const CrudoTextField({
    super.key,
    required this.config,
    this.keyboardType = TextInputType.text,
    this.valueTransformer,
    this.validator,
    this.numeric = false,
    this.maxLines = 1,
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

        // Edit or create
        return FormBuilderTextField(
          name: config.name,
          enabled: config.shouldEnableField(context),
          initialValue:
              context.readFormContext().formData[config.name]?.toString() ?? '',
          validator: FormBuilderValidators.compose([
            if (config.required) FormBuilderValidators.required(),
            if (numeric) FormBuilderValidators.numeric(),
          ]),
          decoration: defaultDecoration.copyWith(labelText: config.label),
          keyboardType: numeric ? TextInputType.number : keyboardType,
          valueTransformer:
              valueTransformer ?? (numeric ? numericTransformer : null),
          maxLines: maxLines,
        );
      }),
    );
  }

  num? numericTransformer(String? value) {
    return value == null
        ? null
        : value == ''
            ? 0
            : num.tryParse(value.toString()) ?? 0;
  }
}
