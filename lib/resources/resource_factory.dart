
import 'package:crud_o/resources/crudo_resource.dart';

abstract class ResourceFactory<T>
{
  T create();
  T createFromJson(Map<String, dynamic> json);
  T createFromFormData(Map<String, dynamic> formData){
    return createFromJson(formData);
  }
}