import 'package:crud_o/core/configuration/crudo_configuration.dart';
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

  /// The internal state of the form, use this to trigger events
  final CrudoFormBloc formBloc;

  /// The results of the future operations
  Map<String, dynamic> futureResults = {};

  /// If the API has been updated since the last time the form was loaded
  final CrudoActionResult formResult = CrudoActionResult();

  /// Listener to invoke when a field changes its value
  Function(String key, dynamic value)? onFieldChange;

  /// Invoke to save the form
  final Function(BuildContext context) save;

  /// Returns true if all the future operations have been loaded
  bool futuresLoaded() => futureResults.isNotEmpty;

  CrudoFormContext(
      {required this.context,
      required this.formBloc,
      required this.save,
      this.validationErrors = const {}});

  //══════════════════════════════════════════════
  // FORM DATA MANAGEMENT
  //══════════════════════════════════════════════

  /// The data of the form
  /// KEEP THIS FINAL AS OTHERWISE EQUATABLE BREAKS
  final Map<String, dynamic> _formData = {};

  /// Get all the form data
  Map<String, dynamic> getFormData() => Map.unmodifiable(_formData);

  /// Get a specific value from the form
  T get<T>(String key) => _formData[key] as T;

  /// Set a specific value in the form
  void set(String key, dynamic value) {
    _formData[key] = value;
    onFieldChange?.call(key, value);
  }

  /// Unset a specific value in the form
  void unset(String key) {
    _formData.remove(key);
  }

  /// Clear all the form data
  void clear() {
    _formData.clear();
  }

  /// Replace the form data with the given data
  void replaceFormData(Map<String, dynamic> data) {
    clear();
    data.forEach((key, value) {
      _formData[key] = value;
    });
  }

  //══════════════════════════════════════════════
  // EXTRA DATA MANAGEMENT (FOR STATE)
  //══════════════════════════════════════════════

  /// Save additional data to be retrieved later, not used by crud-o
  /// This is actually not true at the moment since some internal fields use this
  /// TODO: remove this and use a separate state management solution in those fields
  final Map<String, dynamic> _extraData = {};

  /// Get all the extra data
  Map<String, dynamic> getExtraData() => Map.unmodifiable(_extraData);

  /// Get a specific value for state management
  T getExtra<T>(String key) => _extraData[key] as T;

  /// Set a specific value for state management
  void setExtra(String key, dynamic value) {
    _extraData[key] = value;
  }

  /// Unset a specific value for state management
  void unsetExtra(String key) {
    _extraData.remove(key);
  }

  /// Clear all the extra data
  void clearExtra() {
    _extraData.clear();
  }

  //══════════════════════════════════════════════
  // VALIDATION MANAGEMENT
  //══════════════════════════════════════════════

  /// Errors returned by the validation, either API or local validation
  Map<String, List<String>> validationErrors;

  /// Get all the form errors
  Map<String, List<String>> getFormErrors() =>
      Map.unmodifiable(validationErrors);
  final Map<String, List<CrudoFile>> _formFiles = {};

  /// Invalidate a field
  void invalidateField(String key, String error) {
    if (validationErrors.containsKey(key)) {
      if (!validationErrors[key]!.contains(error)) {
        validationErrors[key]!.add(error);
      }
    } else {
      validationErrors[key] = [error];
    }
  }

  /// Returns true if form has no validation errors, false otherwise
  bool isValid() {
    return validationErrors.isEmpty;
  }

  //══════════════════════════════════════════════
  // FILE MANAGEMENT
  //══════════════════════════════════════════════

  /// Set a specific file group
  void setFiles(String key, List<CrudoFile> files) {
    _formFiles[key] = files;
  }

  /// Get files from the form
  List<CrudoFile>? getFiles(String key) =>
      _formFiles.containsKey(key) ? _formFiles[key] : null;

  //══════════════════════════════════════════════
  // DROPDOWN DATA MANAGEMENT
  //══════════════════════════════════════════════

  /// Save all the dropdown data of the form
  final Map<String, dynamic> _formDropdownData = {};

  /// Save all the dropdown selected values
  final Map<String, dynamic> _formDropdownSelectedValues = {};

  /// Keep track of the future signatures to check weather we need to reload the dropdowns
  final Map<String, int> _formDropdownFutureSignatures = {};

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

  /// Save selected dropdown value
  void setDropdownSelectedValue(String key, dynamic value) {
    _formDropdownSelectedValues[key] = value;
  }

  /// Get selected dropdown value
  T getDropdownSelectedValue<T>(String key) =>
      _formDropdownSelectedValues[key] as T;

  /// Save the future signature of a dropdown
  void setDropdownFutureSignature(String key, int signature) {
    _formDropdownFutureSignatures[key] = signature;
  }

  /// Get the future signature of a dropdown
  int? getDropdownFutureSignature(String key) =>
      _formDropdownFutureSignatures[key];

  //══════════════════════════════════════════════
  // CACHE
  //══════════════════════════════════════════════

  /// Cache here frequently accessed futures
  /// This is pretty useful for dropdowns that are used multiple times in the same form in repeaters
  final Map<String, dynamic> _futureCache = {};

  /// Save the future data in the cache
  void setFutureCache(String key, dynamic data) {
    _futureCache[key] = data;
  }

  /// Get the future data from the cache
  T? getFutureCache<T>(String key) => _futureCache[key] as T?;

  //══════════════════════════════════════════════
  // CONTROLS
  //══════════════════════════════════════════════

  /// Completely reloads the form by getting the data from the API or by starting a new form
  void init() {
    var currentOperationType =
        context.readResourceContext().getCurrentOperationType();
    if (currentOperationType == ResourceOperationType.create) {
      clear();
      formBloc.add(InitFormModelEvent());
    } else if (currentOperationType == ResourceOperationType.edit ||
        currentOperationType == ResourceOperationType.view) {
      formBloc.add(LoadFormModelEvent(id: context.readResourceContext().id));
    }
  }

  /// Builds the form with the given data to re-paint UI with new data
  void rebuild() {
    // Rebuild the form by passing a new map
    formBloc.state is FormReadyState
        ? formBloc
            .add(RebuildFormEvent(formData: Map.from(_formData), force: true))
        : null;
  }

  /// Returns the result of a registered future operation
  T? getFutureResult<T>(String key) => futureResults[key] as T?;

  /// Normalize form data to be sent to the API
  /// This mainly converts repeater fields to a list of objects
  Map<String, dynamic> exportFormData() {
    var exportedData = <String, dynamic>{};
    for (var key in _formData.keys) {
      try {
        var value = _formData[key];

        // Match the key pattern for 'x[index].y' or 'x[index]'
        var match = RegExp(r'^(\w+)\[(\d+)\](?:\.(\w+))?$').firstMatch(key);

        // This is a classic field, not a repeater
        if (match == null) {
          // Fallback to simple assignment for non-nested keys
          exportedData[key] = value;
          continue;
        }

        // Let's handle the repeater now
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
      } catch (e) {
        CrudoConfiguration.logger().e(
            "Error exporting form data for key '$key'", error: e, stackTrace: StackTrace.current);
        continue;
      }
    }

    return exportedData;
  }

}

extension FormContextExtension on BuildContext {
  CrudoFormContext readFormContext() => read<CrudoFormContext>();
}
