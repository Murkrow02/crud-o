import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'crudo_fields.dart';

class CrudoTextField extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;
  final bool numeric;
  final bool decimal;
  final int maxLines;
  final bool obscureText;

  const CrudoTextField({
    super.key,
    required this.config,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.numeric = false,
    this.decimal = false,
    this.maxLines = 1,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return CrudoField(
        config: config,
        editModeBuilder: (context, onChanged) =>
        TextField(
          inputFormatters: decimal ? [DecimalInputFormatter()] : [],
          controller: TextEditingController(
              text: context.readFormContext().get(config.name)?.toString()),
          enabled: config.shouldEnableField(context),
          onChanged: (value) =>
              onChanged(context, (numeric||decimal) ? numericTransformer(value) : value),
          decoration: defaultDecoration,
          keyboardType: (numeric || decimal) ? const TextInputType.numberWithOptions(decimal: true) : keyboardType,
          maxLines: maxLines,
          obscureText: obscureText,
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

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Replace commas with dots
    String newText = newValue.text.replaceAll(',', '.');

    // Allow only digits and dots
    if (RegExp(r'^[0-9.]*$').hasMatch(newText)) {
      return newValue.copyWith(text: newText);
    }
    return oldValue;
  }
}
