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

  /// The (current) operation type of the resource
  /// Can be create, edit, view...
  /// This can change through the lifecycle of the context
  late ResourceOperationType _currentOperationType;

  /// The original operation type of the resource
  /// This can't change through the lifecycle of the context
  final ResourceOperationType operationType;

  /// If the operation type is edit or view, here is the model of the resource
  /// Usually this is pre-loaded when context is fired from the table
  dynamic model;

  /// Extra data passed to the subtree like in form of key-value pairs
  /// Useful if need to pass more data other than the id and operation type
  final Map<String, dynamic> data;

  ResourceContext(
      {required this.id, required this.operationType, this.data = const {}, this.model})
  {
    _currentOperationType = operationType;
  }

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

  /// Set the operation type of the resource
  void setOperationType(ResourceOperationType operationType) {
    _currentOperationType = operationType;
  }

  /// Get the operation type of the resource
  ResourceOperationType getCurrentOperationType() => _currentOperationType;
}

extension ResourceContextExtension on BuildContext {
  ResourceContext readResourceContext() => read<ResourceContext>();
}
