library crudo_fields;

import 'package:flutter/material.dart';

export 'crudo_datetime_field.dart';
export 'crudo_dropdown_field.dart';
export 'crudo_future_dropdown_field.dart';
export 'crudo_table_field.dart';
export 'crudo_text_field.dart';
export 'crudo_repeater_field.dart';
export 'crudo_file_picker.dart';

InputDecoration defaultDecoration(BuildContext context) => InputDecoration(
  floatingLabelBehavior: FloatingLabelBehavior.always,
  labelStyle: const TextStyle(color: Colors.grey),
  filled: true,
  fillColor: Colors.white,
  hintStyle: TextStyle(color: Colors.grey.shade300),
  contentPadding: const EdgeInsets.symmetric(vertical: 19.0, horizontal: 10.0),

  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10.0),
    borderSide: BorderSide.none,
  ),

  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10.0),
    borderSide: BorderSide(width: 1.5, color: Colors.grey.shade200),
  ),

  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10.0),
    borderSide: BorderSide(width: 2, color: Theme.of(context).primaryColor.withAlpha(80) ),
  ),

  // You can simulate the bottom line using a focused `suffix` or `bottom padding` if needed
);
