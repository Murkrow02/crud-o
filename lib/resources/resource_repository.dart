import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/requests/rest_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/crudo_resource.dart';
import 'package:crud_o/resources/resource_client.dart';
import 'package:crud_o/resources/resource_factory.dart';

abstract class ResourceRepository<T> {

  // Wrapped rest client to work with resource
  late ResourceClient<T> _resourceClient;

  // Where to get the resource
  final String endpoint;

  // How to deserialize/create a new resource
  final ResourceFactory<T> factory;
  
  
  ResourceRepository({required this.endpoint, required this.factory}) {
    _resourceClient = ResourceClient(factory);
  }


  Future<T> getById(String id) async {
    return await _resourceClient.getById(endpoint, id);
  }

  Future<PaginatedResourceResponse<T>> getPaginated({PaginatedRequest? request}) async {
    return await _resourceClient.getPaginated(endpoint, request: request);
  }

  Future<void> delete(String id) async {
    return await _resourceClient.delete("$endpoint/$id");
  }

  Future<List<T>> getAll({RestRequest? parameters})=> throw UnimplementedError();


  Future<void> add(T item) async {
    return await _resourceClient.post(endpoint, item);
  }
  Future<void> update(T item)=> throw UnimplementedError();
}