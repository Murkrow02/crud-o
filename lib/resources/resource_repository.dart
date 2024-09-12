import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/requests/rest_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/core/networking/rest/rest_client.dart';
import 'package:crud_o/resources/resource_factory.dart';
import 'package:crud_o/resources/resource_serializer.dart';

abstract class ResourceRepository<T> {

  // Used to make the requests
  final RestClient _client = RestClient();

  // Where to get the resource
  final String endpoint;

  // How to deserialize/create a new resource
  final ResourceFactory<T> factory;

  // How to serialize/convert model to json/map/cells...
  final ResourceSerializer<T> serializer;

  ResourceRepository({required this.endpoint, required this.factory, required this.serializer});


  Future<T> getById(String id) async {
    var decodedBody = await _client.get("$endpoint/$id");
    return factory.createFromJson(decodedBody["data"]);
  }

  Future<PaginatedResourceResponse<T>> getPaginated({PaginatedRequest? request}) async {

    // Normal get operation
    var decodedBody = await _client.get(endpoint, request: request);

    // Create paginated response object
    PaginatedResourceResponse<T> restResponse = PaginatedResourceResponse<T>.fromJson(decodedBody);

    // Deserialize data as a list
    restResponse.data = (decodedBody["data"] as List).map((e) => factory.createFromJsonList(e)).toList();

    return restResponse;
  }

  Future<void> delete(String id) async {
    return await _client.delete("$endpoint/$id");
  }

  Future<List<T>> getAll({RestRequest? parameters}) async {
    var decodedBody = await _client.get(endpoint, request: parameters);
    return (decodedBody["data"] as List).map((e) => factory.createFromJson(e)).toList();
  }

  Future<T> add(T model) async {
    var decodedBody = await _client.post(endpoint, serializer.serializeToJson(model));
    return factory.createFromJson(decodedBody["data"]);
  }
  Future<T> update(T model, String id) async {
    var decodedBody = await _client.put("$endpoint/$id", serializer.serializeToJson(model));
    return factory.createFromJson(decodedBody["data"]);
  }
}