import 'package:crud_o/common/widgets/error_alert.dart';
import 'package:crud_o/core/exceptions/unexpected_state_exception.dart';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/form_context_container.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

abstract class CrudoForm<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends StatelessWidget {
  late TResource resource;
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  String? id;
  ResourceOperationType operationType = ResourceOperationType.create;
  bool updatedApi = false;

  CrudoForm({super.key});

  Map<String, dynamic> _futureResults = {};

  @override
  Widget build(BuildContext context) {
    // Get resource from context
    resource = context.read();

    // Try to get editing resource id
    try {
      id = context.read<ResourceContext>().id;
      operationType = context.read<ResourceContext>().operationType;
    } catch (e) {
      operationType = ResourceOperationType.create;
    }

    return BlocProvider(
      create: (context) => CrudoFormBloc<TResource, TModel>(resource: resource),
      child: Builder(builder: (context) {
        // Execute futures
        _executeFutures(context);

        // Build form
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

              if (state is FormReadyState) {
                return buildFormBuilder(context, state.formData);
              }

              if (state is FormSavingState) {
                return buildFormBuilder(context, state.formData);
              }

              // Form not valid, display the form with errors
              if (state is FormNotValidState) {
                var formData = state.oldFormData;
                if (state.formErrors.isNotEmpty) {
                  _invalidateFormFields(state.formErrors);
                }
                return Column(
                  children: [
                    buildNonFormErrors(context, state.nonFormErrors),
                    buildFormBuilder(context, formData),
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
              if (state is FormModelLoadedState<TModel>) {
                context.read<CrudoFormBloc<TResource, TModel>>().add(
                    ReloadFormEvent(
                        formData: toFormData(state.model),
                        operationType: operationType));
              }
            },
          ),
        );
      }),
    );
  }

  Widget buildFormBuilder(BuildContext context, Map<String, dynamic> formData) {
    return Builder(builder: (context) {
      return Provider(
        create: (context) => FormContextContainer(
          formData: formData,
          formBloc: context.read<CrudoFormBloc<TResource, TModel>>(),
          operationType: operationType,
        ),
        child: Builder(builder: (context) {
          return FormBuilder(
            key: formKey,
            initialValue: formData,
            child: buildForm(context, formData),
          );
        }),
      );
    });
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
    var formData = beforeSave(Map.from(formKey.currentState!.value));
    if (operationType == ResourceOperationType.edit) {
      context.read<CrudoFormBloc<TResource, TModel>>().add(
            UpdateFormModelEvent(formData: formData, id: id!),
          );
    } else if (operationType == ResourceOperationType.create) {
      context.read<CrudoFormBloc<TResource, TModel>>().add(
            CreateFormModelEvent(formData: formData),
          );
    }
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
  Map<String, dynamic> toFormData(TModel model);

  /// Interceptor to modify the form data before saving
  Map<String, dynamic> beforeSave(Map<String, dynamic> formData) {
    return formData;
  }

  /// Reloads the form
  void reloadForm(BuildContext context) {
    var formBloc = context.read<CrudoFormBloc<TResource, TModel>>();
    var formState = formBloc.state;
    if (formState is FormReadyState) {
      formKey.currentState!.save();
      formBloc.add(ReloadFormEvent(
          formData: formKey.currentState!.value, operationType: operationType));
    }
  }

  void enterEditMode(BuildContext context) {
    var editAction = context.read<TResource>().editAction();
    if (editAction == null) return;
    Navigator.of(context).pop();
    editAction.execute(context, data: {'id': id});
  }

  /// Register a list of futures to be executed when the form is loaded
  Map<String, Future> registerFutures(BuildContext context) {
    return {};
  }

  /// Gets the result of a future registered with registerFutures
  T getFutureResult<T>(String key) {
    return _futureResults[key] as T;
  }

  void _executeFutures(BuildContext context) async {
    // Allow child to register futures
    var futures = registerFutures(context);

    // Execute futures
    for (var key in futures.keys) {
      try {
        var result = await futures[key];
        _futureResults[key] = result;
      } catch (e) {
        _futureResults[key] = null;
      }
    }

    // Actually load the form data
    context.read<CrudoFormBloc<TResource, TModel>>().add(
        operationType == ResourceOperationType.create
            ? InitFormModelEvent()
            : LoadFormModelEvent(id: id!));
  }
}
