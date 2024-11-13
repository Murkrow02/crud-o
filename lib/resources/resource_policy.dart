import 'package:crud_o/resources/crudo_resource.dart';

class ResourcePolicy<TModel>
{
  Future<bool> viewAny() async
  {
    return true;
  }

  Future<bool> view(TModel model) async
  {
    return true;
  }

  Future<bool> create() async
  {
    return true;
  }

  Future<bool> update(TModel model) async
  {
    return true;
  }

  Future<bool> delete(TModel model) async
  {
    return true;
  }
}