import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class CrudoTextField extends CrudoField {
  const CrudoTextField(
      {super.key,
        required super.name,
        super.label,
        super.required = false,
        super.visible,
        super.visibleOn,
        super.enabledOn});

  @override
  Widget buildField(BuildContext context) {
    return FormBuilderTextField(
      name: name,
      validator: FormBuilderValidators.compose([
        if (this.required) FormBuilderValidators.required(),
      ]),
      decoration: defaultDecoration.copyWith(labelText: label));
  }
}
