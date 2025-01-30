import 'package:crud_o/resources/actions/crudo_action_result.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/form/data/crudo_file.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

/// This class is needed to pass the form context to the fields
/// Fields are not aware of the resource or model type so we pass a generic bloc + other info
class CrudoFormContext {
  /// The current context of the form
  final BuildContext context;

  /// The data of the form
  /// This is needed in addition to the form key values because it allows us to save arbitrary keys
  /// in addition to the keys that are used by fields in the form
  ///
  /// KEEP THIS FINAL AS OTHERWISE EQUATABLE BREAKS
  final Map<String, dynamic> _formData = {};

  Map<String, dynamic> getFormData() => Map.unmodifiable(_formData);

  Map<String, List<String>> getFormErrors() =>
      Map.unmodifiable(validationErrors);
  final Map<String, List<CrudoFile>> _formFiles = {};

  /// Save all the dropdown data of the form
  final Map<String, dynamic> _formDropdownData = {};

  /// Keep track of the future signatures to check weather we need to reload the dropdowns
  final Map<String, int> formDropdownFutureSignatures = {};

  /// Save additional data to be retrieved later, not used by crud-o
  final Map<String, dynamic> _extraData = {};

  /// The internal state of the form, use this to trigger events
  final CrudoFormBloc formBloc;

  /// Errors returned by the validation, either API or local validation
  Map<String, List<String>> validationErrors;

  /// The results of the future operations
  Map<String, dynamic> futureResults = {};

  /// If the API has been updated since the last time the form was loaded
  final CrudoActionResult formResult = CrudoActionResult();

  /// Listener to invoke when a field changes its value
  Function(String key, dynamic value)? onFieldChange;

  /// Invoke to save the form
  final Function(BuildContext context) save;

  CrudoFormContext({required this.context,
    required this.formBloc,
    required this.save,
    this.validationErrors = const {}});

  /// Get a specific value from the form
  T get<T>(String key) => _formData[key] as T;

  /// Get a specific value for state management
  T getExtra<T>(String key) => _extraData[key] as T;

  /// Get files from the form
  List<CrudoFile>? getFiles(String key) => _formFiles.containsKey(key)
      ? _formFiles[key]
      : null;

  /// Set a specific value in the form
  void set(String key, dynamic value) {
    _formData[key] = value;
    onFieldChange?.call(key, value);
  }

  /// Set a specific value for state management
  void setExtra(String key, dynamic value) {
    _extraData[key] = value;
  }

  /// Unset a specific value in the form
  void unset(String key) {
    _formData.remove(key);
  }

  /// Unset a specific value for state management
  void unsetExtra(String key) {
    _extraData.remove(key);
  }

  /// Clear all the form data
  void clear() {
    _formData.clear();
  }

  /// Clear all the extra data
  void clearExtra() {
    _extraData.clear();
  }

  /// Invalidate a field
  void invalidateField(String key, String error) {
    // Check if the field is already in the list
    if (validationErrors.containsKey(key)) {
      // Check if the error is already in the list
      if (!validationErrors[key]!.contains(error)) {
        validationErrors[key]!.add(error);
      }
    } else {
      validationErrors[key] = [error];
    }

    print('Invalidating field $key with error $error');
  }

  /// Returns true if form has no validation errors, false otherwise
  bool isValid() {
    return validationErrors.isEmpty;
  }

  /// Replace the form data with the given data
  void replaceFormData(Map<String, dynamic> data) {
    clear();
    data.forEach((key, value) {
      _formData[key] = value;
    });
  }

  /// Set a specific file group
  void setFiles(String key, List<CrudoFile> files) {
    _formFiles[key] = files;
  }

  /// Set a specific dropdown values
  void setDropdownData(String key, List<dynamic> data) {
    _formDropdownData[key] = data;
  }

  /// Remove a specific dropdown values
  void removeDropdownData(String key) {
    _formDropdownData.remove(key);
  }

  /// Get a specific dropdown values
  List<T>? getDropdownData<T>(String key) => _formDropdownData[key] as List<T>?;

  /// Get the selected value of a dropdown
  /// TODO: Maybe save this in another list of values, cannot do like this
  // T? getDropdownSelectedModel<T>(String key) {
  //   var dropdownData = context.readFormContext().getDropdownData(key) as Iterable<T>;
  //   var selectedValue = context.readFormContext().get(key);
  //
  // }

  /// Completely reloads the form by getting the data from the API or by starting a new form
  void init() {
    var currentOperationType = context.readResourceContext()
        .getCurrentOperationType();
    if (currentOperationType == ResourceOperationType.create) {
      clear();
      formBloc.add(InitFormModelEvent());
    } else if (currentOperationType == ResourceOperationType.edit ||
        currentOperationType == ResourceOperationType.view) {
      formBloc.add(LoadFormModelEvent(id: context
          .readResourceContext()
          .id));
    }
  }

  /// Builds the form with the given data to re-paint UI with new data
  void rebuild() {
    // Update internal data with the new values
    //syncFormDataFromFields();

    // Rebuild the form by passing a new map
    formBloc.state is FormReadyState
        ? formBloc
        .add(RebuildFormEvent(formData: Map.from(_formData), force: true))
        : null;
  }

  /// Returns the result of a registered future operation
  T? getFutureResult<T>(String key) => futureResults[key] as T?;



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
  CrudoFormContext readFormContext() => read<CrudoFormContext>();
}
