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
  Map<String, dynamic> formData = {};

  /// The internal state of the form, use this to trigger events
  final CrudoFormBloc formBloc;

  /// The actual form key needed to validate or get data from the fields
  final GlobalKey<FormBuilderState> formKey;

  /// Errors returned by the API validation
  Map<String, List<dynamic>> validationErrors;

  /// The results of the future operations
  Map<String, dynamic> futureResults = {};

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
    _syncFormAndInternalValues();

    // Rebuild the form
    formBloc.state is FormReadyState
      ? formBloc.add(RebuildFormEvent(formData: formData))
      : null;
  }

  /// Returns the result of a registered future operation
  T? getFutureResult<T>(String key) => futureResults[key] as T?;

  /// Syncs the form and internal values
  void _syncFormAndInternalValues()
  {
    for(var key in formKey.currentState!.fields.keys)
    {
      formData[key] = formKey.currentState!.fields[key]!.value;
    }
  }

  /// Returns true if all the future operations have been loaded
  bool futuresLoaded() => futureResults.isNotEmpty;
}

extension FormContextExtension on BuildContext {
  FormContext readFormContext() => read<FormContext>();
}
