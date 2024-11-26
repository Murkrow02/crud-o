import 'package:crud_o/resources/form/data/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_future_dropdown_field.dart';
import 'package:flutter/material.dart';

class CrudoDropdownField<TModel, TValue> extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final String errorText;
  final InputDecoration decoration;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;
  final bool multiple;
  final List<TModel>? items;
  final Function(TModel? item)? onSelected;

  const CrudoDropdownField(
      {super.key,
      required this.config,
      required this.items,
      required this.itemBuilder,
      required this.valueBuilder,
      this.decoration = const InputDecoration(),
      this.multiple = false,
      this.errorText = 'Errore nel caricamento dei dati',
      this.onSelected});

  @override
  Widget build(BuildContext context) {
    return CrudoFutureDropdownField<TModel, TValue>(
      config: config,
      retry: false,
      itemBuilder: itemBuilder,
      valueBuilder: valueBuilder,
      futureProvider: items != null
          ? () => Future.value(items)
          : () => _errorFuture().then((value) => value),
      onSelected: onSelected,
    );
  }

  Future<List<TModel>> _errorFuture() => Future.error(errorText);

}
