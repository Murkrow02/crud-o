class CrudoFieldEntry
{
  final String name;
  dynamic _value;
  List<String> _errors = [];

  CrudoFieldEntry(this.name);

  dynamic get value => _value;
  set value(dynamic value) => _value = value;
}
