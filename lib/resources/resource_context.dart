/*
* This class is used to store the context of the resource.
* Is injected in the widget tree to scope the resource to a specific context like table -> form
* We can build widgets without constructors that take the resource as a parameter.
 */
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ResourceContext {

  /// The id of the resource
  /// This can be empty in case of a new resource
  String id;

  /// The operation type of the resource
  /// Can be create, edit, view...
  ResourceOperationType operationType;

  /// If the operation type is edit or view, here is the model of the resource
  /// Usually this is pre-loaded when context is fired from the table
  dynamic model;

  /// Extra data passed to the subtree like in form of key-value pairs
  /// Useful if need to pass more data other than the id and operation type
  Map<String, dynamic> data;
  ResourceContext(
      {required this.id, required this.operationType, this.data = const {}, this.model});

  ResourceContext copyWith(
      {String? id,
      ResourceOperationType? operationType,
      Map<String, dynamic>? data}) {
    return ResourceContext(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      data: data ?? this.data,
    );
  }

  /// Get the model of the resource
  T getModel<T>() => model as T;
}

extension ResourceContextExtension on BuildContext {
  ResourceContext readResourceContext() => read<ResourceContext>();
}
