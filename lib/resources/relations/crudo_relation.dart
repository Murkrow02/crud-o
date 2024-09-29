import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table_page.dart';

abstract class CrudoRelation<TResource extends CrudoResource<TModel>, TModel>
{

  CrudoTablePage<TResource, TModel>? tablePage;


}