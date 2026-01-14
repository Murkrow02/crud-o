import 'package:crud_o_core/resources/crudo_resource.dart';
import 'package:crud_o/resources/form/data/crudo_form_context.dart';
import 'package:crud_o/resources/form/presentation/widgets/crudo_form.dart';
import 'package:crud_o_core/resources/resource_context.dart';
import 'package:crud_o_core/resources/resource_factory.dart';
import 'package:crud_o_core/resources/resource_operation_type.dart';
import 'package:crud_o_core/resources/resource_provider.dart';
import 'package:crud_o_core/resources/resource_repository.dart';
import 'package:crud_o/resources/table/data/crudo_table_context.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/*
* This one is a bit tricky
* We treat the filters as a form, so we need a resource to handle it
* This is useful as user can simply create filters using the same components as the form
* Later, all the form values are used to filter out the table using filter_name => value
*/
class CrudoTableFiltersPopup<TResource extends CrudoResource<TModel>, TModel> extends StatelessWidget {
  final Function(BuildContext context, CrudoTableContext<TResource, TModel> tableContext)? filtersFormBuilder;
  final CrudoTableContext<TResource, TModel> tableContext;

  const CrudoTableFiltersPopup({
    super.key,
    required this.tableContext,
    required this.filtersFormBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return _buildFiltersContent(context);
  }

  Widget _buildFiltersContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle indicator
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(top: 14, bottom: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 20),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.primary.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.filter_alt_rounded,
                        color: colorScheme.primary,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filtri',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Filtra i risultati della tabella',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.55),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.close_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withOpacity(0.5),
              ),

              // Form content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                  child: Provider(
                    create: (_) => ResourceContext(
                      id: '',
                      originalOperationType: ResourceOperationType.edit,
                    ),
                    child: ResourceProvider(
                      create: (_) => CrudoTableFiltersDataResource(),
                      child: Builder(builder: (context) {
                        return CrudoForm<CrudoTableFiltersDataResource, CrudoTableFiltersData>(
                          customSaveIcon: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              border: Border.all(color: colorScheme.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded, size: 20, color: colorScheme.primary),
                                const SizedBox(width: 10),
                                Text(
                                  'Applica',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actionsBuilder: (context) {
                            return [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  context.readFormContext().clear();
                                  tableContext.setFilters({});
                                  Navigator.pop(context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: colorScheme.error, width: 1.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.refresh_rounded, size: 20, color: colorScheme.error),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Reimposta',
                                        style: TextStyle(
                                          color: colorScheme.error,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ];
                          },
                          formBuilder: (context) => filtersFormBuilder!.call(context, tableContext),
                          customSaveAction: (context) async {
                            HapticFeedback.selectionClick();
                            tableContext.setFilters(context.readFormContext().getFormData());
                            Navigator.pop(context);
                          },
                          toFormData: (context, model) {
                            return tableContext.getFiltersData();
                          },
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
