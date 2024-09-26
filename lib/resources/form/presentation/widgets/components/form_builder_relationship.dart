import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:collection/collection.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/components/form_builder_future_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:futuristic/futuristic.dart';
import 'package:provider/provider.dart';

class FormBuilderRelationship<TResource extends CrudoResource<TModel>, TModel,
    TValue> extends StatelessWidget {
  final String name;
  final InputDecoration decoration;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;
  final bool multiple;
  final Function(TModel? item)? onSelected;
  const FormBuilderRelationship({
    super.key,
    required this.itemBuilder,
    required this.name,
    required this.valueBuilder,
    this.decoration = const InputDecoration(),
    this.multiple = false,
    this.onSelected
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilderFutureDropdown(
        itemBuilder: itemBuilder,
        name: name,
        valueBuilder: valueBuilder,
        errorText: 'Non è stato possibile caricare ${context.read<TResource>().pluralName()}',
        future: context.read<TResource>().repository.getAll(),
      onSelected: onSelected,
    );
  }
}
