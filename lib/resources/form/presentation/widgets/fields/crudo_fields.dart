library crudo_fields;

import 'package:flutter/material.dart';

export 'crudo_datetime_field.dart';
export 'crudo_dropdown_field.dart';
export 'crudo_future_dropdown_field.dart';
export 'crudo_table_field.dart';
export 'crudo_text_field.dart';
export 'crudo_repeater_field.dart';
export 'crudo_file_picker.dart';


InputDecoration defaultDecoration = InputDecoration(
  floatingLabelBehavior: FloatingLabelBehavior.always,
  labelStyle: const TextStyle(color: Colors.grey),
  filled: true,
  fillColor: Colors.white,
  contentPadding: const EdgeInsets.symmetric(vertical: 19.0, horizontal: 10.0),
  border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0), borderSide: BorderSide.none),
);

