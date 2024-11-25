import 'dart:collection';
import 'dart:typed_data';

import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/form/data/crudo_file.dart';
import 'package:crud_o/resources/form/data/form_result.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

/// This class is needed to pass the form context to the fields
/// Fields are not aware of the resource or model type so we pass a generic bloc + other info
class FormContext {

  /// The current context of the form
  final BuildContext context;

  /// The data of the form
  /// This is needed in addition to the form key values because it allows us to save arbitrary keys
  /// in addition to the keys that are used by fields in the form
  ///
  /// KEEP THIS FINAL AS OTHERWISE EQUATABLE BREAKS
  final Map<String, dynamic> _formData = {};

  Map<String, dynamic> getFormData() => Map.unmodifiable(_formData);
  final Map<String, List<CrudoFile>> formFiles = {};
  final Map<String, dynamic> formDropdownData = {};
  final Map<String, int> formDropdownFutureSignatures = {
  }; // Keep track of the future signatures to check weather we need to reload the dropdowns


  /// The internal state of the form, use this to trigger events
  final CrudoFormBloc formBloc;

  /// The actual form key needed to validate or get data from the fields
  final GlobalKey<FormBuilderState> formKey;

  /// Errors returned by the API validation
  Map<String, List<dynamic>> validationErrors;

  /// The results of the future operations
  Map<String, dynamic> futureResults = {};

  /// If the API has been updated since the last time the form was loaded
  final ActionResult formResult = ActionResult();

  FormContext({required this.context,
    required this.formBloc,
    required this.formKey,
    this.validationErrors = const {}});

  /// Get a specific value from the form
  T get<T>(String key) => _formData[key] as T;

  /// Get files from the form
  List<CrudoFile>? getFiles(String key) => formFiles[key];

  /// Set a specific value in the form
  void set(String key, dynamic value) {
   // formKey.currentState?.fields[key]?.didChange(value?.toString());
    _formData[key] = value;
  }

  /// Unset a specific value in the form
  void unset(String key) {
   // formKey.currentState?.fields[key]?.didChange(null);
    _formData.remove(key);
  }

  /// Clear all the form data
  void clear() {
    // formKey.currentState?.fields.forEach((key, field) {
    //   field.didChange(null);
    // });
    _formData.clear();
  }

  /// Replace the form data with the given data
  void replaceFormData(Map<String, dynamic> data) {
    clear();
    data.forEach((key, value) {
      //formKey.currentState?.fields[key]?.didChange(value?.toString());
      _formData[key] = value;
    });
  }

  /// Set a specific file group
  void setFiles(String key, List<CrudoFile> files) {
    formFiles[key] = files;
  }

  /// Set a specific dropdown value
  void setDropdownData(String key, List<dynamic> data) {
    formDropdownData[key] = data;
  }

  /// Get a specific dropdown value
  List<T>? getDropdownData<T>(String key) => formDropdownData[key] as List<T>?;

  /// Completely reloads the form by getting the data from the API
  void reload() =>
      formBloc.add(LoadFormModelEvent(id: context
          .readResourceContext()
          .id));

  /// Builds the form with the given data to re-paint UI with new data
  void rebuild() {
    // Update internal data with the new values
    //syncFormDataFromFields();

    // Rebuild the form by passing a new map
    formBloc.state is FormReadyState || formBloc.state is FormNotValidState
        ? formBloc.add(
        RebuildFormEvent(formData: Map.from(_formData), force: true))
        : null;
  }

  /// Returns the result of a registered future operation
  T? getFutureResult<T>(String key) => futureResults[key] as T?;

  // /// Syncs the form and internal values
  // void syncFormDataFromFields() {
  //   //formData.clear(); with this we loose data that is not inside a specific field
  //   formKey.currentState?.fields.forEach((key, field) {
  //     // Check first if the previous value was removed from internal data
  //     if (_formData.containsKey(key)) {
  //       _formData[key] = field.value;
  //     }
  //   });
  // }

  Map<String, dynamic> exportFormData() {
    var exportedData = <String, dynamic>{};
    for (var key in _formData.keys) {
      var value = _formData[key];

      // Match the key pattern for 'x[index].y' or 'x[index]'
      var match = RegExp(r'^(\w+)\[(\d+)\](?:\.(\w+))?$').firstMatch(key);
      if (match != null) {
        var parentKey = match.group(1)!; // 'attributes'
        var indexString = match.group(2)!; // '0'
        var childKey = match.group(3); // 'name', or null if no dot

        // Parse the index
        int index = int.parse(indexString);

        // Ensure parent map exists
        if (!exportedData.containsKey(parentKey)) {
          exportedData[parentKey] = [];
        }

        // Ensure the list has enough elements to accommodate the current index
        var list = exportedData[parentKey] as List?;
        if (list == null) {
          exportedData[parentKey] = list = [];
        }

        while (list.length <= index) {
          list.add(childKey == null ? null : {});
        }

        if (childKey == null) {
          // If there's no second dot, set the list value directly
          list[index] = value;
        } else {
          // If there is a second dot, ensure it's a Map<String, dynamic>
          if (list[index] is! Map<String, dynamic>) {
            list[index] = <String, dynamic>{};
          }

          // Set the nested value inside the map
          (list[index] as Map<String, dynamic>)[childKey] = value;
        }
      } else {
        // Fallback to simple assignment for non-nested keys
        exportedData[key] = value;
      }
    }

    return exportedData;
  }




  /// Returns true if all the future operations have been loaded
  bool futuresLoaded() => futureResults.isNotEmpty;
}

extension FormContextExtension on BuildContext {
  FormContext readFormContext() => read<FormContext>();
}
