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

class CrudoForm<TResource extends CrudoResource<TModel>, TModel extends Object>
    extends StatelessWidget {
  late TResource resource;
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();
  String? id;
  ResourceOperationType operationType = ResourceOperationType.create;
  bool updatedApi = false;
  Map<String, dynamic> _futureResults = {};
  final Function(BuildContext, Map<String, dynamic>, T? Function<T>(String),
      CrudoFormController<TResource, TModel>) formBuilder;
  final Map<String, dynamic> Function(TModel, Map<String, dynamic>) toFormData;
  final Map<String, dynamic> Function(
      Map<String, dynamic>, Map<String, dynamic>)? beforeSave;
  final Map<String, Future> Function()? registerFutures;
  final bool fullPage;

  CrudoForm(
      {super.key,
      required this.formBuilder,
      required this.toFormData,
      this.beforeSave,
      this.registerFutures,
      this.fullPage = false});

  @override
  Widget build(BuildContext context) {
    // Get resource from context
    resource = context.read();

    // Try to get editing resource id
    var resourceContext = context.read<ResourceContext>();
    id = resourceContext.id;
    operationType = resourceContext.operationType;

    return BlocProvider(
      create: (context) => CrudoFormBloc<TResource, TModel>(resource: resource),
      child: Builder(builder: (context) {
        // Execute futures
        _executeFutures(context);

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
                    _buildFormBuilder(context, formData),
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
                if (fullPage) {
                  Navigator.pop(context, updatedApi);
                }

                // // If we were in create mode, we need to switch to edit mode
                // if (operationType == ResourceOperationType.create) {
                //   operationType = ResourceOperationType.edit;
                // }
              }
              if (state is FormModelLoadedState<TModel>) {
                context.read<CrudoFormBloc<TResource, TModel>>().add(
                    RebuildFormEvent(
                        formData: toFormData(state.model, resourceContext.data),
                        operationType: operationType));
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildFormBuilder(
      BuildContext context, Map<String, dynamic> formData) {
    return Provider(
        create: (context) => FormContextContainer(
              formKey: formKey,
              formData: formData,
              formBloc: context.read<CrudoFormBloc<TResource, TModel>>(),
              resourceContext: context.read<ResourceContext>(),
            ),
        child: Builder(builder: (context) {
          return FormBuilder(
              key: formKey,
              initialValue: formData,
              child: formBuilder(context, formData, _getFutureResult,
                  CrudoFormController<TResource, TModel>()));
        }));
  }

  /// These are errors that are not related to a specific field
  Widget _buildNonFormErrors(BuildContext context, List<String> errors) {
    return Column(
        children: errors
            .map((e) => Text(e,
                style: TextStyle(color: Theme.of(context).colorScheme.error)))
            .toList());
  }

  T? _getFutureResult<T>(String key) {
    return _futureResults[key] as T?;
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
  void _executeFutures(BuildContext context) async {
    // Allow child to register futures
    var futures = registerFutures?.call() ?? {};

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

  /// Create a full page form instead of a widget
  Widget _buildFormWrapper(BuildContext context, Widget form) {
    if (!fullPage) {
      return form;
    }
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
                )));
      },
    );
  }

  /// Called when the save button is pressed
  void _onSave(BuildContext context) {
    // Validate and save the form
    var validationSuccess = formKey.currentState!.saveAndValidate();
    if (!validationSuccess) {
      return;
    }

    // Update or create
    var formData = beforeSave?.call(Map.from(formKey.currentState!.value),
            context.read<ResourceContext>().data) ??
        formKey.currentState!.value;
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
}

class CrudoFormController<TResource extends CrudoResource<TModel>,
    TModel extends Object> {
  CrudoFormController();

  /// Builds the form with the given data to re-paint UI with new data
  void rebuildForm(BuildContext context) {
    var formBloc = context.read<CrudoFormBloc<TResource, TModel>>();
    var formContextContainer = context.readFormContext();
    var formState = formBloc.state;
    if (formState is FormReadyState) {
      formContextContainer.formKey.currentState!.save();
      formBloc.add(RebuildFormEvent(
          formData: formContextContainer.formKey.currentState!.value,
          operationType: formContextContainer.resourceContext.operationType));
    }
  }

  /// Completely reloads the form by getting the data from the API
  void reloadForm(BuildContext context) {
    var formBloc = context.read<CrudoFormBloc<TResource, TModel>>();
    var formContextContainer = context.readFormContext();
    formBloc
        .add(LoadFormModelEvent(id: formContextContainer.resourceContext.id));
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
