import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_event.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

abstract class CrudoFormPage<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  String? id;
  bool editMode = true;

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

    return BlocProvider(
      create: (context) =>
          CrudoFormBloc<TResource, TModel>(resource: context.read<TResource>()),
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
            title: Text(context.read<TResource>().singularName()),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {

                  // Validate and save the form
                  var validationSuccess = formKey.currentState!.saveAndValidate();
                  if (!validationSuccess) {
                    return;
                  }

                  if(editMode){

                  } else {
                    var model = context.read<TResource>().repository.factory.createFromFormData(formKey.currentState!.value);
                    context.read<CrudoFormBloc<TResource, TModel>>().add(
                      CreateFormModelEvent<TModel>(model: model),
                    );
                  }
                },
              )
            ],
          ),
          body: BlocBuilder<CrudoFormBloc<TResource, TModel>, CrudoFormState>(
            builder: (context, state) {
              if (state is FormLoadingState) {
                return buildLoading();
              } else if (state is FormReadyState<TModel>) {
                return _buildForm(context, state.model);
              } else if (state is FormValidationErrorState<TModel>) {
                return _buildForm(context, state.model);
              } else if (state is FormErrorState) {
                return Center(child: Text('Error: ${state.error}'));
              }
              return const Center(child: Text('Unknown state'));
            },
          ),
        );
      }),
    );
  }

  Widget _buildForm(BuildContext context, TModel model) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: FormBuilder(
        key: formKey,
        initialValue: context.read<TResource>().toFormData(model),
        child: buildForm(context, model),
      ),
    );
  }

  Widget buildForm(BuildContext context, TModel model);

  Widget buildLoading() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
