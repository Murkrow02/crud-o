import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class CrudoTableColumn<TModel>
{
  final PlutoColumn column;
  bool visible = true;
  bool canBeManuallyHidden = true;
  final PlutoCell Function(TModel model) cellBuilder;
  CrudoTableColumn({required this.column, required this.cellBuilder, this.visible = true, this.canBeManuallyHidden = true});
}