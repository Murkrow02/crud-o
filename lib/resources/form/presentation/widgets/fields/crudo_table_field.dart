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

  const CrudoTableField({
    super.key,
    required this.config,
    required this.table,
  });

  @override
  Widget build(BuildContext context) {

    if(config.reactive)
      throw Exception('CrudoTableField does not yet support reactive fields');

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
            child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: table
            ),
          ),
        );
      }),
    );
  }

}
