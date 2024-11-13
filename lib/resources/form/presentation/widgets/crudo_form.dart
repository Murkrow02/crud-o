import 'package:crud_o/common/widgets/error_alert.dart';
import 'package:crud_o/core/utility/toaster.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';

class CrudoForm<TResource extends CrudoResource<TModel>, TModel extends Object>
    extends StatelessWidget {

  /// The key used to access the form data
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  /// The type of display for the form
  final CrudoFormDisplayType displayType;

  /*
  * Configurations
  */

  /// Build the form fields
  final Function(BuildContext context) formBuilder;

  /// Convert the model to form data
  final Map<String, dynamic> Function(BuildContext context, TModel model)
      toFormData;

  /// Register futures to be executed
  final Map<String, Future> Function(BuildContext context)? registerFutures;

  /*
  * Callbacks
  */

  /// Called before validating the form, should return the final form data to validate
  final Map<String, dynamic> Function(
      BuildContext context, Map<String, dynamic> data)? beforeValidate;

  /// Called before saving the form, should return the final form data to save
  final Map<String, dynamic> Function(
      BuildContext context, Map<String, dynamic> data)? beforeSave;

  /// Called after the form is saved, used to upload files or other operations
  final Function(
      BuildContext context, TModel model)? afterSave;

  /// Called instead of default create
  final Future<TModel> Function(
      BuildContext context, Map<String, dynamic> data)? onCreate;

  /// Called instead of default update
  final Future<TModel> Function(
      BuildContext context, Map<String, dynamic> data)? onUpdate;

  CrudoForm(
      {super.key,
      required this.formBuilder,
      required this.toFormData,
      this.beforeValidate,
      this.beforeSave,
      this.onCreate,
      this.onUpdate,
      this.registerFutures,
        this.afterSave,
      this.displayType = CrudoFormDisplayType.widget});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) =>
            CrudoFormBloc<TResource, TModel>(resource: context.read()),
        child: Provider(
            create: (context) => FormContext(
                context: context,
                formKey: formKey,
                formBloc: context.read<CrudoFormBloc<TResource, TModel>>()),
            child: Builder(builder: (context) {

              // TODO: a possible optimization here is that if the ResourceContext().model is not null and
              // a custom flag is passed to the form it skips the loading of the model and goes directly to the form
              // by triggering the FormReadyState event

              // Actually load the form data
              context.read<CrudoFormBloc<TResource, TModel>>().add(context
                          .readResourceContext()
                          .operationType ==
                      ResourceOperationType.create
                  ? InitFormModelEvent()
                  : LoadFormModelEvent(id: context.readResourceContext().id));

              // Build form
              return _buildFormWrapper(
                context,
                BlocConsumer<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
                  builder: (context, state) {
                    // Form is ready, display the form
                    if (state is FormReadyState) {
                      context.readFormContext().formData.clear();
                      context.readFormContext().formData.addAll(state.formData);
                      return _buildFormBuilder(context);
                    }

                    if (state is FormSavingState) {
                      return _buildFormBuilder(context);
                    }

                    // Form not valid, display the form with errors
                    if (state is FormNotValidState) {
                      context.readFormContext().validationErrors =
                          state.formErrors;
                      if (state.formErrors.isNotEmpty) {
                        _invalidateFormFields(state.formErrors);
                      }
                      return Column(
                        children: [
                          _buildNonFormErrors(context, state.nonFormErrors),
                          _buildFormBuilder(context),
                        ],
                      );
                    }

                    // Form error, display the error
                    if (state is FormErrorState) {
                      return ErrorAlert(state.tracedError);
                    }

                    // For other states, just show a loading spinner
                    return _buildLoading();
                  },
                  listener: (BuildContext context, CrudoFormState state) async {
                    if (state is FormSavedState<TModel>) {
                      // Update the result
                      context.readFormContext().formResult.refreshTable = true;
                      context.readFormContext().formResult.result = state.model;
                      Toaster.success("Salvato!");
                      deserializeModelAndRebuildForm(context, state.model);


                      // Call user provided callback and wait for its completion
                      if (afterSave != null) {
                        await afterSave!(context, state.model);
                      }
                    }
                    if (state is FormModelLoadedState<TModel>) {
                      deserializeModelAndRebuildForm(context, state.model);
                    }
                  },
                ),
              );
            })));
  }

  Widget _buildFormBuilder(BuildContext context) {
    // Build form
    return FormBuilder(
        key: formKey,
        initialValue: context.readFormContext().formData,
        child: formBuilder(context));
  }

  /// These are errors that are not related to a specific field
  Widget _buildNonFormErrors(BuildContext context, List<String> errors) {
    return Column(
        children: errors
            .map((e) => Text(e,
                style: TextStyle(color: Theme.of(context).colorScheme.error)))
            .toList());
  }

  /// Widget rendered when the form is loading
  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  /// Acts after the form has been rendered to invalidate the fields
  /// Goes in reverse order to focus the first error first
  void _invalidateFormFields(Map<String, List> formErrors) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var key in formErrors.keys.toList().reversed) {

        if (!formKey.currentState!.fields.containsKey(key)) {
          Toaster.error(formErrors[key]!.join("\n"));
          continue;
        }
        formKey.currentState!.fields[key]!
            .invalidate(formErrors[key]!.join("\n"));
      }
    });
  }

  /// Execute the futures registered with registerFutures before loading the form
  Future _executeFutures(BuildContext context) async {
    // Check if already loaded futures
    if (context.readFormContext().futuresLoaded()) {
      return;
    }

    // Allow child to register futures
    var futures = registerFutures?.call(context) ?? {};

    // Execute futures
    for (var key in futures.keys) {
      try {
        var result = await futures[key];
        context.readFormContext().futureResults[key] = result;
      } catch (e) {
        context.readFormContext().futureResults[key] = null;
      }
    }
  }

  /// Create a full page form instead of a widget
  Widget _buildFormWrapper(BuildContext context, Widget form) {
    switch (displayType) {
      case CrudoFormDisplayType.fullPage:
        return _buildFullPageFormWrapper(context, form);
      case CrudoFormDisplayType.dialog:
        return _buildDialogFormWrapper(context, form);
      case CrudoFormDisplayType.widget:
        return form;
    }
  }

  Widget _buildDialogFormWrapper(BuildContext context, Widget form) {
    return BlocBuilder<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, __) {
            if (didPop) {
              return;
            }
            Navigator.pop(context, context.readFormContext().formResult);
          },
          child: SimpleDialog(
            title: Text(context.read<TResource>().singularName()),
            children: [
              form,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (state is FormSavingState)
                    const CircularProgressIndicator.adaptive()
                  else if (state is FormNotValidState ||
                      state is FormReadyState)
                    if (context.read<ResourceContext>().operationType ==
                        ResourceOperationType.view)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _enterEditMode(context),
                      )
                    else
                      IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () => _onSave(context)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Called when the save button is pressed
  void _onSave(BuildContext context) {

    // Get data from fields
    context.readFormContext().syncFormDataFromFields();
    var saveData = context.readFormContext().exportFormData();
    context.readFormContext().validationErrors = {};

    // Call before validate callback
    if (beforeValidate != null) {
      saveData = beforeValidate!(context, saveData);
    }

    // Validate form fields
    if (!formKey.currentState!.validate()) {
      context.readFormContext().validationErrors = formKey.currentState!.errors
          .map((key, value) => MapEntry(key, [value]));
      context.readFormContext().rebuild();
      return;
    }

    // Call before save callback
    if (beforeSave != null) {
      saveData = beforeSave!.call(context, saveData);
    }

    // Edit
    if (context.readResourceContext().operationType ==
        ResourceOperationType.edit) {
      if (onUpdate != null) {
        context.readFormContext().formBloc.add(CustomUpdateEvent<TModel>(
            formData: context.readFormContext().formData,
            updateFunction: onUpdate!(context, saveData),
            resourceContext: context.read()));
      } else {
        context.read<CrudoFormBloc<TResource, TModel>>().add(
              UpdateFormModelEvent(
                  updateData: saveData,
                  formData: context.readFormContext().formData,
                  id: context.readResourceContext().id),
            );
      }
    }

    // Create
    if (context.readResourceContext().operationType ==
        ResourceOperationType.create) {
      if (onCreate != null) {
        context.readFormContext().formBloc.add(CustomCreateEvent<TModel>(
          formData: context.readFormContext().formData,
            createFunction: onCreate!(context, saveData),
            resourceContext: context.read()));
      } else {
        context.read<CrudoFormBloc<TResource, TModel>>().add(
              CreateFormModelEvent(
                  formData: context.readFormContext().formData,
                  createData: saveData,
                  resourceContext: context.read()),
            );
      }
    }

    // // Call after save callback
    // MOVE THIS BEFORE RELOADING THE FORM AS WE HAVE TO UPLOAD FILES SO WE NEED BEFORE REFRESHING THE FORM
    // ALSO, WHEN AFTER SAVE GETS CALLED IT SHOULD BE GIVEN THE RESOURCE ID IF JUST CREATED
    // if (afterSave != null) {
    //   afterSave!(context, saveData);
    // }
  }

  void _enterEditMode(BuildContext context) {
    throw UnimplementedError();
    // var editAction = context.read<TResource>().editAction();
    // if (editAction == null) return;
    // editAction.execute(context,
    //     data: {'id': context.readResourceContext().id}).then((needToRefresh) {
    //   if (needToRefresh == true) {
    //     context.readFormContext().formResult.refreshTable = true;
    //     context
    //         .read<CrudoFormBloc<TResource, TModel>>()
    //         .add(LoadFormModelEvent(id: context.readResourceContext().id));
    //   }
    // });
  }

  Widget _buildFullPageFormWrapper(BuildContext context, Widget form) {
    return BlocBuilder<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, __) {
            if (didPop) {
              return;
            }
            Navigator.pop(context, context.readFormContext().formResult);
          },
          child: Scaffold(
              appBar: AppBar(
                title: Text(context.read<TResource>().singularName()),
                actions: [
                  if (state is FormSavingState)
                    const CircularProgressIndicator.adaptive()
                  else if (state is FormNotValidState ||
                      state is FormReadyState)
                    if (context.read<ResourceContext>().operationType ==
                        ResourceOperationType.view)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _enterEditMode(context),
                      )
                    else
                      IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () => _onSave(context)),
                ],
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: form,
                ),
              )),
        );
      },
    );
  }

  /// Converts TModel into a form representation and rebuilds the form
  /// This is useful when loading the form for editing or when we saved the form and want to reload it
  void deserializeModelAndRebuildForm(BuildContext context, TModel model)
  {
    // Set model in resource context
    context.readResourceContext().model = model;

    // Convert model to form data with callback provided
    var formData = toFormData(context, model);
    context.readFormContext().formData.clear();
    context.readFormContext().formData.addAll(formData);

    // Execute futures and rebuild form
    _executeFutures(context).then((_) {
      context
          .read<CrudoFormBloc<TResource, TModel>>()
          .add(RebuildFormEvent(formData: formData));
    });
  }
}

enum CrudoFormDisplayType { fullPage, dialog, widget }
