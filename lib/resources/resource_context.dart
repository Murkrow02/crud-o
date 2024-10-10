/*
* This class is used to store the context of the resource.
* Is injected in the widget tree to scope the resource to a specific context like table -> form
* We can build widgets without constructors that take the resource as a parameter.
 */
import 'package:crud_o/resources/resource_operation_type.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class ResourceContext {
  String id;
  ResourceOperationType operationType;
  Map<String, dynamic> data;
  ResourceContext(
      {required this.id, required this.operationType, this.data = const {}});

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
}

extension ResourceContextExtension on BuildContext {
  ResourceContext readResourceContext() => read<ResourceContext>();
}
