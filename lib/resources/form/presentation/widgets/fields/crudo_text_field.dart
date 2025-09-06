import 'package:crud_o_core/lang/temp_lang.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_field_wrapper.dart';
import 'package:crud_o_core/resources/resource_operation_type.dart';
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

    // When focus is lost, make sure the *final* text is committed to the form.
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        final numeric = widget.decimal || widget.numeric;
        final val = _controller.text;
        final committed = numeric ? numericTransformer(val) : val;
        // Use the field wrapper's onChanged to push to your form state.
        // We'll call the onChanged passed in build via a helper.
        _commitLatest(committed);
      }
    });
  }

  void _commitLatest(dynamic value) {
    // This will be set by build() each frame.
    _latestOnChanged?.call(context, value);
  }

  // We'll capture the onChanged callback from CrudoField each build.
  void Function(BuildContext, dynamic)? _latestOnChanged;

  @override
  void didUpdateWidget(covariant CrudoTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Pull the value from the form only when we're not editing,
    // and only if it's non-null and actually different.
    final newValue =
    context.readFormContext().get(widget.config.name)?.toString();

    if (!_focusNode.hasFocus && newValue != null && _controller.text != newValue) {
      // Update text without losing cursor/IME composing ranges unexpectedly.
      _controller.value = _controller.value.copyWith(
        text: newValue,
        selection: TextSelection.collapsed(offset: newValue.length),
        composing: TextRange.empty,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final numeric = widget.decimal || widget.numeric;

    return CrudoField(
      config: widget.config,
      editModeBuilder: (context, onChanged) {
        // keep a reference so _commitLatest() can push reliably
        _latestOnChanged = onChanged;

        return TextField(
          controller: _controller,
          focusNode: _focusNode,
          inputFormatters: widget.decimal ? [DecimalInputFormatter()] : [],
          enabled: widget.config.shouldEnableField(context),

          // Push on every keystroke as before
          onChanged: (value) {
            onChanged(
              context,
              numeric ? numericTransformer(value) : value,
            );
          },

          // Make the keyboard's return act as "Done" (dismiss)
          textInputAction: widget.maxLines == 1
              ? TextInputAction.done
              : TextInputAction.newline,

          // When user taps Done, commit the final text and close keyboard
          onSubmitted: (value) {
            onChanged(context, numeric ? numericTransformer(value) : value);
            _focusNode.unfocus();
          },

          // Also fires on blur; ensures last autocorrect is saved
          onEditingComplete: () {
            final value = _controller.text;
            onChanged(context, numeric ? numericTransformer(value) : value);
          },

          // (Optional) if you don't want iOS autocorrect to “change” text on blur:
          // autocorrect: false,
          // enableSuggestions: false,

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
    return value == null || value.isEmpty ? null : num.tryParse(value) ?? 0;
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
