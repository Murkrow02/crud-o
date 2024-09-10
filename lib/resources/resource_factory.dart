
import 'package:crud_o/resources/crudo_resource.dart';

abstract class ResourceFactory<T>
{
  T create();

  // Generic method to create a model from a map, this is the default also for the other methods
  // You should only override this method if your model behaves the same way when deserializing from a map, json or form data
  // Otherwise, you should override the other methods
  T createFromMap(Map<String, dynamic> map) => throw UnimplementedError();

  // Called when deserializing a single model from a json object
  T createFromJson(Map<String, dynamic> json)
  {
    return createFromMap(json);
  }

  // Called when deserializing a list of models from a json object
  T createFromJsonList(Map<String, dynamic> json)
  {
    return createFromJson(json);
  }

  // Called when deserializing a model from a form data
  T createFromFormData(Map<String, dynamic> formData){
    return createFromMap(formData);
  }
}