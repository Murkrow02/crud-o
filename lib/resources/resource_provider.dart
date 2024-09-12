import 'package:crud_o/auth/widgets/crudo_auth_wrapper.dart';
import 'package:crud_o/resources/table/presentation/pages/crudo_table_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'crudo_resource.dart';

class RegisteredResources {
   final List<CrudoResource> _resources = [];
   final List<CrudoTablePage> _tables = [];
   final List<Type> _types = [];
   void registerResource<TResource extends CrudoResource<TModel>, TModel>(TResource resource) {
      if (_types.contains(TResource)) {
        return;
      }
      _types.add(TResource);
     _resources.add(resource);
     _tables.add(CrudoTablePage<TResource, TModel>());
   }
   List<CrudoTablePage> get tables => _tables;
    List<CrudoResource> get resources => _resources;
}

class ResourceProvider<TResource extends CrudoResource, TModel> extends Provider<TResource> {

  final TResource Function(BuildContext context) create;
  ResourceProvider({
    required this.create,
    super.key,
    super.child,
    super.lazy,
  }) : super(
    create: create,
    dispose: (_, __) {},
  );

  ResourceProvider.value({
    required super.value,
    required this.create,
    super.key,
    super.child,
  }) : super.value();

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    RegisteredResources? resources;
    try {
      resources = Provider.of<RegisteredResources>(context, listen: false);
    } catch (e) {
      resources = RegisteredResources();
    }
    resources.registerResource(create(context));
    return Provider(
        create: (_) => resources,
        child: super.buildWithChild(context, child));
  }

  /// Method to access the repository instance from the context.
  static T of<T>(BuildContext context, {bool listen = false}) {
    try {
      return Provider.of<T>(context, listen: listen);
    } on ProviderNotFoundException catch (e) {
      if (e.valueType != T) rethrow;
      throw FlutterError(
        '''
        ResourceProvider.of() called with a context that does not contain a repository of type $T.
        No ancestor could be found starting from the context that was passed to ResourceProvider.of<$T>().

        This can happen if the context you used comes from a widget above the ResourceProvider.

        The context used was: $context
        ''',
      );
    }
  }
}


class MultiResourceProvider extends MultiProvider {
  final List<dynamic> _createdRepositories = [];

  MultiResourceProvider({
    required super.providers,
    required Widget super.child,
    super.key,
  });
}
