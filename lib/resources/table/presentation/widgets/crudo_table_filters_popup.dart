import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_form.dart';
import 'package:crud_o/resources/resource_context.dart';
import 'package:crud_o/resources/resource_factory.dart';
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:crud_o/resources/resource_provider.dart';
import 'package:crud_o/resources/resource_repository.dart';
import 'package:crud_o/resources/table/data/crudo_table_context.dart';
import 'package:flutter/material.dart';
import 'package:pluto_grid_plus/pluto_grid_plus.dart';
import 'package:provider/provider.dart';

class CrudoTableFiltersPopup<TResource extends CrudoResource<TModel>, TModel> extends StatelessWidget {
  final Function(BuildContext context,CrudoTableContext<TResource,TModel> tableContext)? filtersBuilder;
  final CrudoTableContext<TResource,TModel> tableContext;

  const CrudoTableFiltersPopup(
      {super.key, required this.tableContext, required this.filtersBuilder});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
        icon: const Icon(Icons.filter_alt_outlined),
        tooltip: 'Filtri',
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              enabled: false,
              child: _buildFiltersForm(context),
            )
          ];
        });
  }

  Widget _buildFiltersForm(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    double popUpWidth = screenWidth > 600 ? 600 : screenWidth * 0.9;
    return SizedBox(
      width: popUpWidth,
      child: Provider(
        create: (_) => ResourceContext(
            id: '', originalOperationType: ResourceOperationType.edit),
        child: ResourceProvider(
            create: (_) => CrudoTableFiltersDataResource(),
            child: Builder(builder: (context) {
              return Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.filter_alt_outlined),
                      const SizedBox(width: 10),
                      Text('Filtri', style: TextStyle(fontSize: 20))
                    ],
                  ),
                  CrudoForm<CrudoTableFiltersDataResource,
                          CrudoTableFiltersData>(
                      customSaveIcon: const Text('Applica',
                          style: TextStyle(color: Colors.blue)),
                      actionsBuilder: (context) {
                        return [
                          TextButton(
                              onPressed: () {
                                context.readFormContext().clear();
                                tableContext.setFilters({});
                                Navigator.pop(context);
                              },
                              child: const Text("Reset",
                                  style: const TextStyle(color: Colors.red)))
                        ];
                      },
                      formBuilder: (context) => filtersBuilder!.call(context,tableContext),
                      customSaveAction: (context) async {
                        tableContext.setFilters(context.readFormContext().getFormData());
                        Navigator.pop(context);
                      },
                      toFormData: (context, model) {
                        return tableContext.getFiltersData();
                      }),
                ],
              );
            })),
      ),
    );
  }
}

class CrudoTableFiltersData {}

class CrudoTableFiltersDataResource
    extends CrudoResource<CrudoTableFiltersData> {
  CrudoTableFiltersDataResource()
      : super(repository: CrudoTableFiltersDataRepository());

  @override
  String pluralName() => '';

  @override
  String singularName() => '';
}

class CrudoTableFiltersDataRepository
    extends ResourceRepository<CrudoTableFiltersData> {
  CrudoTableFiltersDataRepository()
      : super(endpoint: '', factory: CrudoTableFiltersDataFactory());

  @override
  Future<CrudoTableFiltersData> getById(String id) async {
    return CrudoTableFiltersData();
  }
}

class CrudoTableFiltersDataFactory
    extends ResourceFactory<CrudoTableFiltersData> {
  @override
  CrudoTableFiltersData create() {
    return CrudoTableFiltersData();
  }
}
