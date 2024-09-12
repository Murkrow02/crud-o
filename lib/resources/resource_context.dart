/*
* This class is used to store the context of the resource.
* Is injected in the widget tree to provide the resource context to the widgets like tables, forms, etc.
* We can build widgets without constructors that take the resource as a parameter.
 */
class ResourceContext {
  final String id;

  ResourceContext({required this.id});
}