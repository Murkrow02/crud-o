import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class CrudoTableColumn<TModel>
{
  final PlutoColumn column;
  final PlutoCell Function(TModel model) cellBuilder;

  CrudoTableColumn({required this.column, required this.cellBuilder});
}