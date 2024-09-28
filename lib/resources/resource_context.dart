/*
* This class is used to store the context of the resource.
* Is injected in the widget tree to scope the resource to a specific context like table -> form
* We can build widgets without constructors that take the resource as a parameter.
 */
import 'package:crud_o/resources/resource_operation_type.dart';

class ResourceContext {
  final String id;
  final ResourceOperationType operationType;
  ResourceContext({required this.id, required this.operationType});
}