/// This object is returned when the action is resolved
/// Typically used to refresh the table when a form page pops
class CrudoActionResult
{
  bool refreshTable;
  dynamic result;
  CrudoActionResult({this.refreshTable = false});
}