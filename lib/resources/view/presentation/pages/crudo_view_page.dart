import 'package:crud_o/common/widgets/error_alert.dart';
import 'package:crud_o/core/exceptions/unexpected_state_exception.dart';
import 'package:crud_o/core/models/traced_error.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/view/bloc/crudo_view_bloc.dart';
import 'package:crud_o/resources/view/bloc/crudo_view_event.dart';
import 'package:crud_o/resources/view/bloc/crudo_view_state.dart';
import 'package:crud_o/resources/view/presentation/widgets/view_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class CrudoViewPage<TResource extends CrudoResource<TModel>,
    TModel extends Object> extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey = GlobalKey<FormBuilderState>();

  late String id;
  late TResource resource;
  CrudoViewPage({super.key});

  @override
  Widget build(BuildContext context) {
    resource = context.read();
    id = context.read<ResourceContext>().id;

    return BlocProvider(
      create: (context) =>
          CrudoViewBloc<TResource, TModel>(resource: resource)
            ..add(
              LoadViewEvent<TModel>(id: id),
            ),
      child: Builder(builder: (context) {
        return Scaffold(
          appBar: AppBar(
            title: Text(resource.singularName()),
            actions: resource.editAction() != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        var action = resource.editAction()!;
                        action.execute(context, data: {'id': id}).then(
                          (shouldRefresh) {
                            if (shouldRefresh == true) {
                              context.read<CrudoViewBloc<TResource, TModel>>().add(
                                LoadViewEvent<TModel>(id: id),
                              );
                            }
                          }
                        );
                      },
                    ),
                  ]
                : [],
          ),
          body: BlocBuilder<CrudoViewBloc<TResource, TModel>, CrudoViewState>(
            builder: (context, state) {
              // Model is ready
              if (state is ViewReadyState<TModel>) {
                return buildView(context, modelToView(state.model));
              }

              // Some error occurred
              else if (state is ViewErrorState) {
                return ErrorAlert(state.tracedError);
              } else if (state is ViewLoadingState) {
                return buildLoading(context);
              }

              return ErrorAlert(TracedError(
                  UnexpectedStateException(state), StackTrace.current));
            },
          ),
        );
      }),
    );
  }

  /// Override this method to build custom view
  Widget buildView(BuildContext context, Map<String, dynamic> previewFields) {
    return SingleChildScrollView(
      child: Column(
        children: [
          for (var key in previewFields.keys)
            ViewField(name: key, value: previewFields[key].toString()),
        ],
      ),
    );
  }

  /// Override this method to build custom loading widget
  Widget buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  /// Override this method to convert model to view fields
  Map<String, dynamic> modelToView(TModel model) {
    return resource.toMap(model);
  }
}
