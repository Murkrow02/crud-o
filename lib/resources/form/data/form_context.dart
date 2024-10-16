import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
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
  final Map<String, dynamic> formData = {};

  /// The internal state of the form, use this to trigger events
  final CrudoFormBloc formBloc;

  /// The actual form key needed to validate or get data from the fields
  final GlobalKey<FormBuilderState> formKey;

  /// Errors returned by the API validation
  Map<String, List<dynamic>> validationErrors;

  /// The results of the future operations
  Map<String, dynamic> futureResults = {};

  /// If the API has been updated since the last time the form was loaded
  bool updatedApi = false;

  FormContext(
      {required this.context,
      required this.formBloc,
      required this.formKey,
      this.validationErrors = const {}});

  /// Get a specific value from the form
  T get<T>(String key) => formData[key] as T;

  /// Set a specific value in the form
  void set(String key, dynamic value) {
    formKey.currentState?.fields[key]?.didChange(value);
    formData[key] = value;
  }

  /// Completely reloads the form by getting the data from the API
  void reload() =>
      formBloc.add(LoadFormModelEvent(id: context.readResourceContext().id));

  /// Builds the form with the given data to re-paint UI with new data
  void rebuild() {

    // Update internal data with the new values
    syncFormDataFromFields();


    // Rebuild the form by passing a new map
    formBloc.state is FormReadyState || formBloc.state is FormNotValidState
        ? formBloc.add(RebuildFormEvent(formData: Map.from(formData)))
        : null;
  }

  /// Returns the result of a registered future operation
  T? getFutureResult<T>(String key) => futureResults[key] as T?;

  /// Syncs the form and internal values
  void syncFormDataFromFields() {
    formData.clear();
    formKey.currentState?.fields.forEach((key, field) {
      formData[key] = field.value;
    });
  }

  Map<String, dynamic> exportFormData() {
    var exportedData = <String, dynamic>{};
    for (var key in formKey.currentState!.fields.keys) {
      var value = formKey.currentState!.fields[key]!.value;

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
        var list = exportedData[parentKey] as List;
        while (list.length <= index) {
          list.add(childKey == null ? null : {}); // Add null for list, map otherwise
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
