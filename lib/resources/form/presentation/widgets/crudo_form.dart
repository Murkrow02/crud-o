import 'package:crud_o/common/widgets/error_alert.dart';
import 'package:crud_o/common/widgets/save_and_close_icon.dart';
import 'package:crud_o/common/widgets/save_and_create_another_icon.dart';
import 'package:crud_o/common/widgets/save_and_edit_icon.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o_core/core/utility/toaster.dart';
import 'package:crud_o_core/resources/crudo_form_display_type.dart';
import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o_core/resources/resource_operation_type.dart';
import 'package:crud_o_core/resources/resource_context.dart';
import 'package:crud_o_core/ui/confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:futuristic/futuristic.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';

class CrudoForm<TResource extends CrudoResource<TModel>, TModel extends Object>
    extends StatelessWidget {
  /// The type of display for the form
  final CrudoFormDisplayType displayType;

  //══════════════════════════════════════════════
  // Configurations
  //══════════════════════════════════════════════

  /// Build the form fields
  final Widget Function(BuildContext context) formBuilder;

  /// Build the form fields (optional for view mode only)
  final Widget Function(BuildContext context)? viewFormBuilder;

  /// Custom title on top of the form
  final String? customTitle;

  /// Convert the model to form data
  final Map<String, dynamic> Function(BuildContext context, TModel model)
      toFormData;

  /// Extra data to be passed to the form
  final Map<String, dynamic> Function(BuildContext context)? extraData;

  /// Register futures to be executed
  final Map<String, Future> Function(BuildContext context)? registerFutures;

  //══════════════════════════════════════════════
  // Callbacks
  //══════════════════════════════════════════════

  /// Called before validating the form, should return the final form data to validate
  final Map<String, dynamic> Function(
      BuildContext context, Map<String, dynamic> data)? beforeValidate;

  /// Called before saving the form, should return the final form data to save
  final Map<String, dynamic> Function(
      BuildContext context, Map<String, dynamic> data)? beforeSave;

  /// Called after the form is saved, used to upload files or other operations
  final Function(BuildContext context, TModel model)? afterSave;

  /// Called instead of default create
  final Future<TModel> Function(
      BuildContext context, Map<String, dynamic> data)? onCreate;

  /// Called instead of default update
  final Future<TModel> Function(
      BuildContext context, Map<String, dynamic> data)? onUpdate;

  /// Called whenever a field is changed
  final void Function(BuildContext context, String key, dynamic value)?
      onFieldChange;

  //══════════════════════════════════════════════
  // Actions
  //══════════════════════════════════════════════

  /// Save behavior
  final CrudoFormSaveBehaviour saveBehaviour;

  /// Save icon
  final Widget? customSaveIcon;

  /// Custom save action
  final Function(BuildContext context)? customSaveAction;

  /// Custom actions builder
  final List<Widget> Function(BuildContext context)? actionsBuilder;

  /// Show a popup to create a new item after saving
  /// This is obviously disabled if saveBehaviour is by default saveAndCreateAnother
  final CreateAnotherConfiguration? createAnotherConfiguration;

  const CrudoForm(
      {super.key,
      required this.formBuilder,
      this.viewFormBuilder,
      required this.toFormData,
      this.extraData,
      this.beforeValidate,
      this.customTitle,
      this.beforeSave,
      this.onCreate,
      this.onUpdate,
      this.customSaveIcon,
      this.customSaveAction,
      this.registerFutures,
      this.onFieldChange,
      this.saveBehaviour = CrudoFormSaveBehaviour.saveAndClose,
      this.afterSave,
      this.createAnotherConfiguration,
      this.actionsBuilder,
      this.displayType = CrudoFormDisplayType.widget});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) =>
            CrudoFormBloc<TResource, TModel>(resource: context.read()),
        child: Provider(
            create: (context) => CrudoFormContext(
                context: context,
                save: _onSave,
                formBloc: context.read<CrudoFormBloc<TResource, TModel>>()),
            child: Builder(builder: (context) {
              // TODO: a possible optimization here is that if the ResourceContext().model is not null and
              // a custom flag is passed to the form it skips the loading of the model and goes directly to the form
              // by triggering the FormReadyState event

              // Init or enter editing mode
              context.readFormContext().init();

              // Listen for field changes
              context.readFormContext().onFieldChange = (key, value) {
                onFieldChange?.call(context, key, value);
              };

              // Set form extra data if provided
              if (extraData != null) {
                for (var key in extraData!(context).keys) {
                  context
                      .readFormContext()
                      .setExtra(key, extraData!(context)[key]);
                }
              }

              // Build form
              return _buildFormWrapper(
                  context,
                  BlocConsumer<CrudoFormBloc<TResource, TModel>,
                      CrudoFormState>(
                    builder: (context, state) {
                      // Form is ready, display the form
                      if (state is FormReadyState) {
                        _checkAndDisplayFormErrors(context, state.apiErrors);
                        context
                            .readFormContext()
                            .replaceFormData(state.formData);
                        return _buildForm(context);
                      }

                      if (state is FormSavingState) {
                        return _buildLoading();
                      }

                      // Form error, display the error
                      if (state is FormErrorState) {
                        return ErrorAlert(state.tracedError);
                      }

                      // For other states, just show a loading spinner
                      return _buildLoading();
                    },
                    listener:
                        (BuildContext context, CrudoFormState state) async {
                      if (state is FormSavedState<TModel>) {
                        _afterSave(context, state.model);
                        // Clear extra data
                      }

                      if (state is FormModelLoadedState<TModel>) {
                        _deserializeModelAndRebuildForm(context, state.model);
                      }
                    },
                  ));
            })));
  }

  /// Build form based on the operation type
  Widget _buildForm(BuildContext context) {
    return context.readResourceContext().getCurrentOperationType() ==
                ResourceOperationType.view &&
            viewFormBuilder != null
        ? viewFormBuilder!(context)
        : formBuilder(context);
  }

  /// Detect display type and build the form wrapper accordingly
  Widget _buildFormWrapper(BuildContext context, Widget form) {
    switch (displayType) {
      case CrudoFormDisplayType.fullPage:
        return _buildFullPageFormWrapper(context, form);
      case CrudoFormDisplayType.dialog:
        return _buildDialogFormWrapper(context, form);
      case CrudoFormDisplayType.widget:
        return _buildWidgetWrapper(context, form);
      case CrudoFormDisplayType.widgetPlain:
        return _buildWidgetPlainWrapper(context, form);
    }
  }

  /// Build the form wrapper for a full page
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
                title: Text(_getFormTitle(context)),
                actions: [
                  if (state is FormSavingState)
                    const CircularProgressIndicator.adaptive()
                  else if (state is FormReadyState) ...[
                    ..._buildFormActions(context)
                  ]
                ],
              ),
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: form,
              )),
        );
      },
    );
  }

  /// Form wrapped to be displayed in a dialog
  Widget _buildDialogFormWrapper(BuildContext context, Widget form) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, __) {
        if (didPop) {
          return;
        }
        Navigator.pop(context, context.readFormContext().formResult);
      },
      child: Dialog(child: _buildWidgetWrapper(context, form)),
    );
  }

  Widget _buildWidgetWrapper(BuildContext context, Widget form) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocBuilder<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
          builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25),
                  child: Text(_getFormTitle(context),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                if (state is FormSavingState)
                  const CircularProgressIndicator.adaptive()
                else if (state is FormReadyState)
                  ..._buildFormActions(context)
              ],
            ),
            form
          ],
        );
      }),
    );
  }

  Widget _buildWidgetPlainWrapper(BuildContext context, Widget form) {
    return BlocBuilder<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
        builder: (context, state) {
          return form;
        });
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

  List<Widget> _buildFormActions(BuildContext context) {
    return [
      // Custom user actions
      if (actionsBuilder != null) ...actionsBuilder!(context),

      // Enter edit mode action (only if able to edit)
      if (context.readResourceContext().getCurrentOperationType() ==
          ResourceOperationType.view)
        Futuristic<bool>(
            futureBuilder: () =>
                context
                    .read<TResource>()
                    .policy
                    ?.update(context.readResourceContext().model) ??
                Future.value(false),
            autoStart: true,
            busyBuilder: (_) => const CircularProgressIndicator.adaptive(),
            dataBuilder: (context, canEdit) {
              if(canEdit == null || canEdit == false) {
                return const SizedBox();
              }
              return IconButton(
                  icon: const Icon(Icons.edit),
                  style: ButtonStyle(
                      padding:
                          WidgetStateProperty.all(const EdgeInsets.all(2))),
                  onPressed: () => _enterEditMode(context));
            }),

      // Save action
      if (context.readResourceContext().getCurrentOperationType() !=
          ResourceOperationType.view)
        IconButton(
            icon: customSaveIcon ?? const Icon(Icons.save),
            style: ButtonStyle(
                padding: WidgetStateProperty.all(const EdgeInsets.all(2))),
            onPressed: () => _onSave(context)),
    ];
  }

  /// Called when the save button is pressed
  void _onSave(BuildContext context) {
    try {


      if (customSaveAction != null) {
        customSaveAction!(context);
        return;
      }


      // Validate form fields TODO

      // Get data from fields
      var saveData = context.readFormContext().exportFormData();
      context.readFormContext().validationErrors = {};



      // Call before validate callback
      if (beforeValidate != null) {
        saveData = beforeValidate!(context, saveData);
      }


      // Call before save callback
      if (beforeSave != null) {
        saveData = beforeSave!.call(context, saveData);
      }


      // Edit
      if (context.readResourceContext().getCurrentOperationType() ==
          ResourceOperationType.edit) {
        if (onUpdate != null) {

          context.readFormContext().formBloc.add(CustomUpdateEvent<TModel>(
              formData: context.readFormContext().getFormData(),
              updateFunction: onUpdate!(context, saveData)));

        } else {

          context.read<CrudoFormBloc<TResource, TModel>>().add(
                UpdateFormModelEvent(
                    updateData: saveData,
                    formData: context.readFormContext().getFormData(),
                    id: context.readResourceContext().id),
              );
        }

      }

      // Create
      if (context.readResourceContext().getCurrentOperationType() ==
          ResourceOperationType.create) {
        if (onCreate != null) {


          context.readFormContext().formBloc.add(CustomCreateEvent<TModel>(
              formData: context.readFormContext().getFormData(),
              createFunction: onCreate!(context, saveData)));


        } else {

          context.read<CrudoFormBloc<TResource, TModel>>().add(
                CreateFormModelEvent(
                    formData: context.readFormContext().getFormData(),
                    createData: saveData,
                    resourceContext: context.read()),
              );


        }
      }
    } catch (e, s) {
      CrudoConfiguration.logger().e("Error during save",
          time: DateTime.now(), error: e, stackTrace: s);
    }
  }

  void _enterEditMode(BuildContext context) {
    context.readResourceContext().setOperationType(ResourceOperationType.edit);
    context.readFormContext().init();
  }

  /// Converts TModel into a form representation and rebuilds the form
  /// This is useful when loading the form for editing or when we saved the form and want to reload it
  void _deserializeModelAndRebuildForm(BuildContext context, TModel model) {
    // Set model in resource context
    context.readResourceContext().model = model;

    // Convert model to form data with callback provided
    var formData = toFormData(context, model);
    context.readFormContext().replaceFormData(formData);

    // Execute futures and rebuild form
    _executeFutures(context).then((_) {
      context
          .read<CrudoFormBloc<TResource, TModel>>()
          .add(RebuildFormEvent(formData: formData));
    });
  }

  /// Called whenever a new resource is created or updated and API returned the updated model
  void _afterSave(BuildContext context, TModel model) async {
    // Set the new id
    context.readResourceContext().id = context.read<TResource>().getId(model);

    // Save what was the operation
    var oldOperation = context.readResourceContext().originalOperationType;

    // Now we are in edit mode
    context.readResourceContext().setOperationType(ResourceOperationType.edit);

    // Update the form result
    context.readFormContext().formResult.refreshTable = true;
    context.readFormContext().formResult.result = model;
    Toaster.success("Salvato!");

    // Deserialize model and rebuild form with new data
    _deserializeModelAndRebuildForm(context, model);

    // Call user provided callback and wait for its completion
    if (afterSave != null) {
      await afterSave!.call(context, model);
    }

    // Clear extra data since we are now dealing with another resource
    // This is critical and used in mainly in crudo_repeater_field to re-flatten data after a new form is rendered
    context.readFormContext().clearExtra();

    // Check if need to create another resource
    if (oldOperation == ResourceOperationType.create &&
        saveBehaviour == CrudoFormSaveBehaviour.saveAndCreateAnother) {
      var needToCreateAnother = createAnotherConfiguration == null
          ? true
          : await ConfirmationDialog.ask(
              context: context,
              title: createAnotherConfiguration!.title,
              message: createAnotherConfiguration!.message,
              okText: createAnotherConfiguration!.okText,
              cancelText: createAnotherConfiguration!.cancelText);
      if (needToCreateAnother == true) {
        // This is needed again i don't know why
        context.readFormContext().clearExtra();
        context
            .readResourceContext()
            .setOperationType(ResourceOperationType.create);
        context.readFormContext().init();
        return;
      }
    }

    // Check save action provided by user
    if (saveBehaviour == CrudoFormSaveBehaviour.saveAndEdit) {
      // Nothing to do
    } else if (saveBehaviour == CrudoFormSaveBehaviour.saveAndClose) {
      Navigator.pop(context, context.readFormContext().formResult);
    }
  }

  /// Check if the form is valid and display errors if not
  void _checkAndDisplayFormErrors(
      BuildContext context, Map<String, List<String>>? apiErrors) {
    if (!context.readFormContext().isValid() || apiErrors != null) {
      // Add api errors to form errors
      if (apiErrors != null) {
        apiErrors!.forEach((key, value) {
          for (var error in value) {
            context.readFormContext().invalidateField(key, error);
          }
        });
      }

      var formErrors = context.readFormContext().getFormErrors();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reverse order to show errors from top to bottom
        for (var key in formErrors.keys.toList().reversed) {
          // Check if field is rendered
          var formData = context.readFormContext().getFormData();
          if (!formData.containsKey(key)) {
            Toaster.error("$key: " + formErrors[key]!.join("\n"));
            continue;
          }

          // Invalidate form field with errors
          for (var error in formErrors[key]!) {
            context.readFormContext().invalidateField(key, error);
          }
        }
      });
    }
  }

  /// Get the title of the form
  String _getFormTitle(BuildContext context) {
    return customTitle ?? context.read<TResource>().singularName();
  }
}

enum CrudoFormSaveBehaviour { saveAndCreateAnother, saveAndEdit, saveAndClose }

class CreateAnotherConfiguration {
  final String title;
  final String message;
  final String? okText;
  final String? cancelText;

  CreateAnotherConfiguration(
      {required this.title,
      required this.message,
      this.okText,
      this.cancelText});
}
