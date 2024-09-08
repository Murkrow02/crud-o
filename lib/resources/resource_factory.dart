
import 'package:crud_o/resources/resource.dart';

abstract class ResourceFactory<T>
{
  T create();
  T createFromJson(Map<String, dynamic> json);
}