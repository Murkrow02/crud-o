/// This object is returned when the action is resolved
/// Typically used to refresh the table when a form page pops
class ActionResult
{
  bool refreshTable;
  ActionResult({this.refreshTable = false});
}