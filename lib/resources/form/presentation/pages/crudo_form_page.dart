import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/form/data/form_context_container.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_form.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// This is basically a wrapper arund the CrudoForm widget that adds a PopScope and a navigation bar
/// You can use this instead of the CrudoForm widget if you want to have a full page form
abstract class CrudoFormPage<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends CrudoForm<TResource, TModel> {
  CrudoFormPage({super.key});

  @override
  Widget buildFormWrapper(BuildContext context, Widget form) {
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
                          onPressed: () => enterEditMode(context),
                        )
                      else
                        IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () => onSave(context),
                        ),
                  ],
                ),
                body: super.buildFormWrapper(context, form)));
      },
    );
  }
}
