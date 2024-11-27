import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/requests/rest_request.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_field.dart';
import 'package:crud_o/resources/form/data/form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/fields/crudo_future_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CrudoResourceDropdown<TResource extends CrudoResource<TModel>, TModel,
TValue> extends StatelessWidget {
  final CrudoFieldConfiguration config;
  final InputDecoration decoration;
  final Widget Function(TModel item) itemBuilder;
  final TValue Function(TModel item) valueBuilder;
  final String? searchHintText;
  final bool nullable;
  final int minSearchLength;

  const CrudoResourceDropdown({super.key,
    required this.config,
    required this.itemBuilder,
    required this.valueBuilder,
    this.nullable = false,
    this.searchHintText,
    this.minSearchLength = 1,
    this.decoration = const InputDecoration()});

  @override
  Widget build(BuildContext context) {
    return CrudoFutureDropdownField<TModel, TValue>(
      config: config,
      retry: false,
      itemBuilder: itemBuilder,
      valueBuilder: valueBuilder,
      nullable: nullable,
      searchHintText: searchHintText,
      minSearchLength: minSearchLength,
      futureProvider: () async {
        var alreadySelectedId = context.readFormContext().get(config.name);
        return context
            .read<TResource>()
            .repository
            .getAll()
            .then((value) async {
          if (alreadySelectedId == null) {
            return value;
          }

          // Get also the individual selected resource and add it to the already existing list
          return value
            ..removeWhere((dynamic element) => element.id == alreadySelectedId) // Maybe selected item is already in list
              // Add the selected item to the list
            ..add(await context
                .read<TResource>()
                .repository
                .getById(alreadySelectedId.toString()));
        });
      },
      searchFuture: (String query) async {
        return context
            .read<TResource>()
            .repository
            .getAll(parameters: RestRequest(search: query));
      },
    );
  }
}
