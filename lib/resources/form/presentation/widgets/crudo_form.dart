import 'package:crud_o/common/widgets/error_alert.dart';
import 'package:crud_o/core/exceptions/unexpected_state_exception.dart';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

abstract class CrudoForm<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends StatelessWidget {
  late TResource resource;
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  // If in edit mode, the id of the resource
  String? id;

  // Indicates edit/create mode
  bool editMode = true;

  // Indicates if the api has been updated with the new data, used to refresh the table
  bool updatedApi = false;

  CrudoForm({super.key});

  @override
  Widget build(BuildContext context) {
    resource = context.read();

    // Try to get editing resource id
    try {
      id = context.read<ResourceContext>().id;
    } catch (e) {
      // If the id is not present, it means we are creating a new resource
      editMode = false;
    }

    return BlocProvider(
        create: (context) =>
            CrudoFormBloc<TResource, TModel>(resource: resource)
              ..add(editMode
                  ? LoadFormModelEvent<TModel>(id: id!)
                  : InitFormModelEvent()),
        child: Builder(builder: (context) {
          return buildFormWrapper(
            context,
            BlocConsumer<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
              builder: (context, state) {
                // Loading, saved or initial state
                if (state is FormLoadingState ||
                    state is FormSavedState ||
                    state is FormInitialState) {
                  return buildLoading();
                }

                // Form ready (or saving), display the form
                if (state is FormReadyState<TModel> ||
                    state is FormSavingState) {
                  var formData = state is FormReadyState<TModel>
                      ? _cleanFormData(modelToForm(state.model))
                      : (state as FormSavingState).formData;
                  return FormBuilder(
                      key: formKey,
                      initialValue: formData,
                      child: buildForm(context, formData));
                }

                // Form not valid, display the form with errors
                if (state is FormNotValidState) {
                  var formData = _cleanFormData(state.oldFormData);
                  if (state.formErrors.isNotEmpty) {
                    _invalidateFormFields(state.formErrors);
                  }
                  return Column(
                    children: [
                      buildNonFormErrors(context, state.nonFormErrors),
                      FormBuilder(
                          key: formKey,
                          initialValue: formData,
                          child: buildForm(
                            context,
                            formData,
                          ))
                    ],
                  );
                }

                // Form error, display the error
                if (state is FormErrorState) {
                  return ErrorAlert(state.tracedError);
                }

                // Unexpected state
                return ErrorAlert(TracedError(
                    UnexpectedStateException(state), StackTrace.current));
              },
              listener: (BuildContext context, CrudoFormState state) {
                if (state is FormSavedState) {
                  updatedApi = true;
                  Toaster.success("Salvato!");
                }
              },
            ),
          );
        }));
  }

  /// Override to create your form
  Widget buildForm(BuildContext context, Map<String, dynamic> formData);

  /// These are errors that are not related to a specific field
  Widget buildNonFormErrors(BuildContext context, List<String> errors) {
    return Column(
        children: errors
            .map((e) => Text(e,
                style: TextStyle(color: Theme.of(context).colorScheme.error)))
            .toList());
  }

  /// Widget rendered when the form is loading
  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Override to wrap the form with additional widget (e.g. a scroll view)
  Widget buildFormWrapper(BuildContext context, Widget form) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: form,
      ),
    );
  }

  /// Called when the save button is pressed
  void onSave(BuildContext context) {
    // Validate and save the form
    var validationSuccess = formKey.currentState!.saveAndValidate();
    if (!validationSuccess) {
      return;
    }

    // Update or create
    var model = formToModel(formKey.currentState!.value);
    if (editMode) {
      context.read<CrudoFormBloc<TResource, TModel>>().add(
            UpdateFormModelEvent(
                formData: formKey.currentState!.value, id: id!, model: model),
          );
    } else {
      context.read<CrudoFormBloc<TResource, TModel>>().add(
            CreateFormModelEvent(
                formData: formKey.currentState!.value, model: model),
          );
    }
  }

  /// Form builder needs all values to be string so we ensure that here
  Map<String, dynamic> _cleanFormData(Map<String, dynamic> formData) {
    return formData.map((key, value) {
      // Date time is good
      if (value is DateTime) {
        return MapEntry(key, value);
      }

      return MapEntry(key, value.toString());
    });
  }

  /// Acts after the form has been rendered to invalidate the fields
  /// Goes in reverse order to focus the first error first
  void _invalidateFormFields(Map<String, List> formErrors) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var key in formErrors.keys.toList().reversed) {
        formKey.currentState!.fields[key]!
            .invalidate(formErrors[key]!.join("\n"));
      }
    });
  }

  /// By default, form falls back to the resource serializer to serialize the form data
  /// Override this method to customize the serialization
  Map<String, dynamic> modelToForm(TModel model) {
    return resource.serializer.serializeToMap(model);
  }

  TModel formToModel(Map<String, dynamic> formData);
}
