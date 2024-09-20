import 'package:crud_o/common/widgets/error_alert.dart';
import 'package:crud_o/core/exceptions/unexpected_state_exception.dart';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_bloc.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_event.dart';
import 'package:crud_o/resources/table/bloc/crudo_table_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

abstract class CrudoFormPage<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  // If in edit mode, the id of the resource
  String? id;

  // Indicates edit/create mode
  bool editMode = true;

  // Indicates if the api has been updated with the new data, used to refresh the table
  bool updatedApi = false;

  CrudoFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Try to get editing resource id
    try {
      id = context.read<ResourceContext>().id;
    } catch (e) {
      // If the id is not present, it means we are creating a new resource
      editMode = false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, __) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, updatedApi);
      },
      child: BlocProvider(
        create: (context) => CrudoFormBloc<TResource, TModel>(
            resource: context.read<TResource>()),
        child: Builder(builder: (context) {
          // Create or load the form model based on the editMode
          if (editMode) {
            context
                .read<CrudoFormBloc<TResource, TModel>>()
                .add(LoadFormModelEvent<TModel>(id: id!));
          } else {
            context
                .read<CrudoFormBloc<TResource, TModel>>()
                .add(InitFormModelEvent());
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(context.read<TResource>().singularName(),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => onSave(context),
                ),
              ],
            ),
            body:
                BlocConsumer<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
              builder: (context, state) {
                // Loading, saved or initial state
                if (state is FormLoadingState ||
                    state is FormSavedState ||
                    state is FormInitialState) {
                  return buildLoading();
                }

                // Form ready, display the form
                if (state is FormReadyState) {
                  return _buildForm(context, state.formData);
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
        }),
      ),
    );
  }

  Widget _buildForm(BuildContext context, Map<String, dynamic> previousData,
      {List<String> validationErrors = const []}) {

    List<String> nonFormErrors = [];  // Errors that are not related to a specific field
    for (var key in validationErrors) {
      if (!formKey.currentState!.fields.containsKey(key)) {
        nonFormErrors.add(key);
      }
      else {
        // Invalidation of the form field
        formKey.currentState!.fields[key]!.invalidate(validationErrors.join('\n'));
      }
    }

    return Column(
      children: [
        buildNonFormErrors(context, nonFormErrors),
        FormBuilder(
          key: formKey,
          initialValue: previousData,
          child: buildForm(context, previousData),
        ),
      ],
    );
  }

  /// Override to create your form
  Widget buildForm(BuildContext context, Map<String, dynamic> previousData);

  /// These are errors that are not related to a specific field
  Widget buildNonFormErrors(BuildContext context, List<String> errors) {
    return Column(
      children: errors.map((e) => Text(e)).toList(),
    );
  }

  /// Widget rendered when the form is loading
  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
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
    if (editMode) {
      context.read<CrudoFormBloc<TResource, TModel>>().add(
            UpdateFormModelEvent(
                formData: formKey.currentState!.value, id: id!),
          );
    } else {
      context.read<CrudoFormBloc<TResource, TModel>>().add(
            CreateFormModelEvent(formData: formKey.currentState!.value),
          );
    }
  }
}
