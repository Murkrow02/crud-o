import 'package:crud_o/lang/temp_lang.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'crudo_fields.dart';

class CrudoTextField extends StatefulWidget {
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
  State<CrudoTextField> createState() => _CrudoTextFieldState();
}

/*
  * All the state management shit is just to re-gain focus after rebuild when
  * the field is reactive ;)
*/
class _CrudoTextFieldState extends State<CrudoTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    final value = context.readFormContext().get(widget.config.name)?.toString();
    _controller = TextEditingController(text: value);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CrudoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newValue = context.readFormContext().get(widget.config.name)?.toString();
    if (_controller.text != newValue) {
      _controller.text = newValue ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final numeric = widget.decimal || widget.numeric;

    return CrudoField(
      config: widget.config,
      editModeBuilder: (context, onChanged) {
        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          inputFormatters: widget.decimal ? [DecimalInputFormatter()] : [],
          enabled: widget.config.shouldEnableField(context),
          onChanged: (value) {
            onChanged(
              context,
              numeric ? numericTransformer(value) : value,
            );
          },
          decoration: defaultDecoration(context).copyWith(
            hintText: widget.config.placeholder,
          ),
          keyboardType: numeric
              ? TextInputType.numberWithOptions(decimal: widget.decimal)
              : widget.keyboardType,
          maxLines: widget.maxLines,
          obscureText: widget.obscureText,
        );
      },
    );
  }

  num? numericTransformer(String? value) {
    return value == null
        ? null
        : value == ''
            ? null
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
