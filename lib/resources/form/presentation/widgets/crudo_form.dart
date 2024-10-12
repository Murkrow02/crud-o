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

  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  String? id;
  ResourceOperationType operationType = ResourceOperationType.create;
  bool updatedApi = false;
  final CrudoFormDisplayType displayType;

  /*
  * Configurations
  */

  /// Build the form fields
  final Function(BuildContext context) formBuilder;

  /// Convert the model to form data
  final Map<String, dynamic> Function(BuildContext context, TModel model) toFormData;

  /// Register futures to be executed
  final Map<String, Future> Function(BuildContext context)? registerFutures;

  /*
  * Callbacks
  */

  /// Called before validating the form, should return the final form data to validate
  final Function(BuildContext context)? beforeValidate;

  /// Called before saving the form, should return the final form data to save
  final Function(BuildContext context)? beforeSave;

  /// Called instead of default create
  final void Function(BuildContext context)? onCreate;

  /// Called instead of default update
  final void Function(BuildContext context)? onUpdate;

  CrudoForm(
      {super.key,
      required this.formBuilder,
      required this.toFormData,
      this.beforeValidate,
      this.beforeSave,
      this.onCreate,
      this.onUpdate,
      this.registerFutures,
      this.displayType = CrudoFormDisplayType.none});

  @override
  Widget build(BuildContext context) {

    // Try to get editing resource id
    var resourceContext = context.read<ResourceContext>();
    id = resourceContext.id;
    operationType = resourceContext.operationType;

    return BlocProvider(
        create: (context) =>
            CrudoFormBloc<TResource, TModel>(resource: context.read()),
        child: Provider(
            create: (context) => FormContext(
              context: context,
                formKey: formKey,
                formBloc: context.read<CrudoFormBloc<TResource, TModel>>()),
            child: Builder(builder: (context) {

              // Actually load the form data
              context.read<CrudoFormBloc<TResource, TModel>>().add(
                  operationType == ResourceOperationType.create
                      ? InitFormModelEvent()
                      : LoadFormModelEvent(id: id!));

              // Build form
              return _buildFormWrapper(
                context,
                BlocConsumer<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
                  builder: (context, state) {
                    if (state is FormReadyState) {
                      return _buildFormBuilder(context, state.formData);
                    }

                    if (state is FormSavingState) {
                      return _buildFormBuilder(context, state.formData);
                    }

                    // Form not valid, display the form with errors
                    if (state is FormNotValidState) {
                      var formData = state.oldFormData;
                      if (state.formErrors.isNotEmpty) {
                        _invalidateFormFields(state.formErrors);
                      }
                      return Column(
                        children: [
                          _buildNonFormErrors(context, state.nonFormErrors),
                          _buildFormBuilder(context, formData,
                              validationErrors: state.formErrors),
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
                  listener: (BuildContext context, CrudoFormState state) {
                    if (state is FormSavedState) {
                      updatedApi = true;
                      Toaster.success("Salvato!");
                    }
                    if (state is FormModelLoadedState<TModel>) {

                      // Convert model to form data with callback provided
                      var formData = toFormData(context, state.model);

                      // Execute futures and rebuild form
                      _executeFutures(context).then((_) {
                        context.read<CrudoFormBloc<TResource, TModel>>().add(
                            RebuildFormEvent(formData: formData));
                      });
                    }
                  },
                ),
              );
            })));
  }

  Widget _buildFormBuilder(BuildContext context, Map<String, dynamic> formData,
      {Map<String, List> validationErrors = const {}}) {

    // Update form context
    context.readFormContext().validationErrors = validationErrors;
    context.readFormContext().formData.clear();
    context.readFormContext().formData.addAll(formData);

    // Build form
    return FormBuilder(
        key: formKey,
        initialValue: formData,
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
      case CrudoFormDisplayType.none:
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
            Navigator.pop(context, updatedApi);
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

    // Call before validate callback
    if (beforeValidate != null) {
      beforeValidate!(context);
    }

    // Validate form fields
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Call before save callback
    if (beforeSave != null) {
      beforeSave!.call(context);
    }

    // Edit
    if (context.readResourceContext().operationType ==
        ResourceOperationType.edit) {
      if (onUpdate != null) {
        onUpdate!(context);
      } else {
        context.read<CrudoFormBloc<TResource, TModel>>().add(
              UpdateFormModelEvent(formData: context.readFormContext().formData, id: id!),
            );
      }
    }

    // Create
    if (context.readResourceContext().operationType ==
        ResourceOperationType.create) {
      if (onCreate != null) {
        onCreate!(context);
      } else {
        context.read<CrudoFormBloc<TResource, TModel>>().add(
              CreateFormModelEvent(
                  formData: context.readFormContext().formData, resourceContext: context.read()),
            );
      }
    }
  }

  void _enterEditMode(BuildContext context) {
    var editAction = context.read<TResource>().editAction();
    if (editAction == null) return;
    editAction.execute(context, data: {'id': id}).then((needToRefresh) {
      if (needToRefresh == true) {
        updatedApi = true;
        context
            .read<CrudoFormBloc<TResource, TModel>>()
            .add(LoadFormModelEvent(id: id!));
      }
    });
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
            Navigator.pop(context, updatedApi);
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
}

class CrudoFormController<TResource extends CrudoResource<TModel>,
    TModel extends Object> {
  CrudoFormController();

  /// Builds the form with the given data to re-paint UI with new data
  void rebuildForm(BuildContext context) {
    throw UnimplementedError("Rebuild form not implemented from controller");
    var formBloc = context.read<CrudoFormBloc<TResource, TModel>>();
    var formContext = context.readFormContext();
    var formState = formBloc.state;
    if (formState is FormReadyState) {
      formContext.formKey.currentState!.save();
      formBloc.add(
          RebuildFormEvent(formData: formContext.formKey.currentState!.value));
    }
  }

  /// Completely reloads the form by getting the data from the API
  void reloadForm(BuildContext context) {
    throw UnimplementedError("Reload form not implemented from controller");
    var formBloc = context.read<CrudoFormBloc<TResource, TModel>>();
    var resourceContext = context.readResourceContext();
    formBloc.add(LoadFormModelEvent(id: resourceContext.id));
  }

  void enterEditMode(BuildContext context) {
    // just an idea to implement: get bloc and add event to trigger on listener in the main widget
    throw UnimplementedError("Enter edit mode not implemented from controller");
  }

  void save(BuildContext context) {
    // just an idea to implement: get bloc and add event to trigger on listener in the main widget
    throw UnimplementedError("Save not implemented from controller");
  }
}

enum CrudoFormDisplayType { fullPage, dialog, none }
