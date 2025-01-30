import 'package:pluto_grid_plus/pluto_grid_plus.dart';

class CrudoTableColumn<TModel>
{
  final PlutoColumn column;
  bool visible = true;

  // If false, using the table settings menu the user can't hide/show this column
  bool canBeManuallyHidden = true;
  final PlutoCell Function(TModel model) cellBuilder;
  CrudoTableColumn({required this.column, required this.cellBuilder, this.visible = true, this.canBeManuallyHidden = true});
}