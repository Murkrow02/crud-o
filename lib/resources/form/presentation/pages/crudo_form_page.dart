import 'package:crud_o/resources/form/bloc/crudo_form_bloc.dart';
import 'package:crud_o/resources/form/bloc/crudo_form_state.dart';
import 'package:crud_o/resources/resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

abstract class CrudoFormPage<TResource extends CrudoResource<TModel>, TModel extends Object>
    extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  CrudoFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (context) =>
        CrudoFormBloc<TResource, TModel>(resource: context.read<TResource>()),
        child: BlocBuilder(
            builder: (context, state) {
          if (state is FormLoadingState) {
            return buildLoading();
          } else if (state is FormReadyState<TModel>) {
            return buildForm(context, state.model);
          } else if (state is FormValidationErrorState<TModel>) {
            return buildForm(context, state.model);
          } else if (state is FormErrorState) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return const Center(child: Text('Unknown state'));
        },
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
