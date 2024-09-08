import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/requests/rest_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/resource.dart';
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


  // Future<T> getById(int id) async {
  //   return factory.create();
  //   //return (await _restClient.get<T>("${getEndpoint()}/$id")).data;
  // }

  Future<PaginatedResourceResponse<T>> getPaginated({PaginatedRequest? request}) async {
    return await _resourceClient.getPaginated(endpoint, request: request);
  }

  Future<List<T>> getAll({RestRequest? parameters})=> throw UnimplementedError();


  Future<void> add(T item) => throw UnimplementedError();
  Future<void> update(T item)=> throw UnimplementedError();
  Future<void> delete(T item)=> throw UnimplementedError();
}