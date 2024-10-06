import 'package:crud_o/auth/bloc/crudo_auth_wrapper_bloc.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:provider/provider.dart';
import 'crudo_field.dart';

class CrudoTableField<TResource extends CrudoResource<TModel>, TModel>
    extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final CrudoTable<TResource, TModel> table;
  final Map<String, dynamic>? createData;
  final Widget? modalForm;

  const CrudoTableField({
    super.key,
    required this.config,
    this.modalForm,
    required this.table,
    this.createData,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.shouldRenderField(context)) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Builder(builder: (context) {
        // Detect if preview
        if (config.shouldRenderViewField(context)) {
          return CrudoViewField(
              name: config.label ?? config.name, child: table);
        }

        return CrudoErrorize(
          error: config.getValidationError(context),
          child: CrudoLabelize(
            offset: 8,
            label: config.label ?? config.name,
            child: FormBuilderField(
              name: config.name,
              builder: (FormFieldState<dynamic> field) {
                return Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (context.read<TResource>().createAction() != null)
                          IconButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    Theme
                                        .of(context)
                                        .colorScheme
                                        .primary),
                              ),
                              onPressed: () => onCreateClicked(context),
                              icon: const Icon(Icons.add, color: Colors.white)),
                        table,
                      ],
                    ));
              },
            ),
          ),
        );
      }),
    );
  }

  void onCreateClicked(BuildContext context) async {
    if (modalForm != null) {
      await showDialog(
        context: context,
        builder: (context) =>
            Provider(
              create: (context) =>
                  ResourceContext(
                      id: "", operationType: ResourceOperationType.create),
              child: modalForm!,
            ),
      );
      return;
    }

    context
        .read<TResource>()
        .createAction()!
        .execute(context, data: createData ?? {})
        .then((needRefresh) {
      if (needRefresh) {
        table.onDataChanged?.call(false);
      }
    });
  }
}
