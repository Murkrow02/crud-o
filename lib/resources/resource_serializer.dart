import 'package:pluto_grid_plus/pluto_grid_plus.dart';

abstract class ResourceSerializer<T>
{

  Map<String, dynamic> serializeToMap(T model);

  Map<String, dynamic> serializeToJson(T model)
  {
    return serializeToMap(model);
  }

  Map<String, dynamic> serializeToView(T model)
  {
    return serializeToMap(model);
  }

  Map<String, dynamic> serializeToFormData(T model) {
    return serializeToMap(model);
  }

  Map<String, PlutoCell> serializeToCells(T model) {
    return serializeToMap(model).map((propertyName, propertyValue) {
      return MapEntry(propertyName, PlutoCell(value: propertyValue));
    });
  }
}