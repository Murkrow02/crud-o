import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_errorize.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_labelize.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table.dart';
import 'package:flutter/material.dart';

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
              config: config, child: table);
        }

        return CrudoField(
          config: config,
          builder: (context, onChanged) => CrudoLabelize(
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
