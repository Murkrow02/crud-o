import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
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
    if (config.reactive) {
      throw Exception('CrudoTextField does not yet support reactive fields');
    }

    // Detect if preview
    if (config.shouldRenderViewField(context)) {
      return CrudoViewField(
          config: config,
          child: Text(
              context.readFormContext().get(config.name)?.toString() ?? ''));
    }

    // Edit or create
    return CrudoFieldWrapper(
        config: config,
        errorize: false,
        child: FormBuilderTextField(
          name: config.name,
          enabled: config.shouldEnableField(context),
          onChanged: (value) {
            context.readFormContext().set(config.name, numeric ? numericTransformer(value) : value);
          },

          // This is needed since form builder does not like ints as initial values
          initialValue: context
              .readFormContext().get(config.name)?.toString(),
          validator: FormBuilderValidators.compose([
            if (config.required) FormBuilderValidators.required(
                errorText: TempLang.requiredField),
            if (numeric)
              FormBuilderValidators.numeric(checkNullOrEmpty: config.required,
                  errorText: TempLang.numericField),
          ]),
          decoration: defaultDecoration,
          keyboardType: numeric ? TextInputType.number : keyboardType,
          valueTransformer:
          valueTransformer ?? (numeric ? numericTransformer : null),
          maxLines: maxLines,
        ));
  }

  num? numericTransformer(String? value) {
    return value == null
        ? null
        : value == ''
        ? 0
        : num.tryParse(value.toString()) ?? 0;
  }
}
