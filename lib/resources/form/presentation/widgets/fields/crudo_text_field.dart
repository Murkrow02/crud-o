import 'package:crud_o/resources/form/data/form_context_container.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class CrudoTextField extends CrudoField {
  final TextInputType keyboardType;
  final ValueTransformer<String?>? valueTransformer;
  final FormFieldValidator<String>? validator;
  final bool numeric;
  final int maxLines;
  const CrudoTextField({
    super.key,

    // Super fields
    required super.name,
    super.label,
    super.required = false,
    super.visible,
    super.visibleOn,
    super.enabledOn,

    // This class fields
    this.keyboardType = TextInputType.text,
    this.valueTransformer,
    this.validator,
    this.numeric = false,
    this.maxLines = 1,
  });

  @override
  Widget buildField(BuildContext context) {

    return FormBuilderTextField(
      name: name,
      initialValue: context.readFormContext().formData[name]?.toString() ?? '',
      validator: FormBuilderValidators.compose([
        if (this.required) FormBuilderValidators.required(),
        if (this.numeric) FormBuilderValidators.numeric(),
      ]),
      decoration: defaultDecoration.copyWith(labelText: label),
      keyboardType: numeric ? TextInputType.number : keyboardType,
      valueTransformer: valueTransformer ?? (numeric ? numericTransformer : null),
      maxLines: this.maxLines,
    );
  }

  num? numericTransformer(String? value)
  {
    return value == null
        ? null
        : value == ''
        ? 0
        : num.tryParse(value.toString()) ?? 0;
  }
}
