import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/requests/rest_request.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_future_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrudoResourceDropdown<TResource extends CrudoResource<TModel>, TModel, TValue> extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final InputDecoration decoration;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;
  final Function(TModel? item)? onSelected;

  const CrudoResourceDropdown(
      {super.key,
      required this.config,
      required this.itemBuilder,
      required this.valueBuilder,
      this.decoration = const InputDecoration(),
      this.onSelected});

  @override
  Widget build(BuildContext context) {
    return CrudoFutureDropdownField<TModel, TValue>(
      config: config,
      retry: false,
      itemBuilder: itemBuilder,
      valueBuilder: valueBuilder,
      onSelected: onSelected,
      futureProvider: () {
        return context.read<TResource>().repository.getAll();
      },
      searchFuture: (String query) async {
        return context.read<TResource>().repository.getAll(parameters: RestRequest(search: query));
      },
    );
  }

}
