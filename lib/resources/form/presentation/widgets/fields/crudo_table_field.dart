import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_view_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_errorize.dart';
import 'package:crud_o/resources/form/presentation/widgets/wrappers/crudo_labelize.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table.dart';
import 'package:crud_o_core/configuration/crudo_configuration.dart';
import 'package:flutter/material.dart';

/// A styled table field with modern design.
/// Embeds a CrudoTable within a form field container.
class CrudoTableField<TResource extends CrudoResource<TModel>, TModel>
    extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final CrudoTable<TResource, TModel> table;
  final double? height;

  const CrudoTableField({
    super.key,
    required this.config,
    required this.table,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = CrudoConfiguration.theme();
    final colorScheme = Theme.of(context).colorScheme;

    if (config.reactive) {
      throw Exception('CrudoTableField does not yet support reactive fields');
    }

    final borderColor = theme.fieldBorderColor ??
        colorScheme.outline.withOpacity(0.2);

    return CrudoField(
      config: config,
      editModeBuilder: (context, onChanged) => Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.fieldBorderRadius),
          color: theme.fieldFillColor ?? colorScheme.surface,
          border: Border.all(
            color: borderColor,
            width: theme.fieldBorderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.fieldBorderRadius - 1),
          child: table,
        ),
      ),
      viewModeBuilder: (context) => CrudoViewField(
        config: config,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.viewFieldBorderRadius - 1),
          child: table,
        ),
      ),
    );
  }

}
