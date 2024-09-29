import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/requests/rest_request.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/core/networking/rest/rest_client.dart';
import 'package:crud_o/resources/resource_factory.dart';

abstract class ResourceRepository<T> {

  // Used to make the requests
  final RestClient _client = RestClient();

  // Where to get the resource
  final String endpoint;

  // How to deserialize/create a new resource
  final ResourceFactory<T> factory;


  ResourceRepository(
      {required this.endpoint,
      required this.factory,
      this.memoryCacheDuration});


  /// **************************************************************************************************
  /// Endpoint calls
  /// **************************************************************************************************

  Future<T> getById(String id) async {
    var decodedBody = await _client.get("$endpoint/$id");
    return factory.createFromJson(decodedBody["data"]);
  }

  Future<PaginatedResponse<T>> getPaginated(
      {PaginatedRequest? request}) async {
    // Normal get operation
    var decodedBody = await _client.get(endpoint, request: request);

    // Create paginated response object
    PaginatedResponse<T> restResponse =
        PaginatedResponse<T>.fromJson(decodedBody);

    // Deserialize data as a list
    restResponse.data = (decodedBody["data"] as List)
        .map((e) => factory.createFromJsonList(e))
        .toList();

    return restResponse;
  }

  Future<void> delete(String id) async {
    return await _client.delete("$endpoint/$id");
  }

  Future<List<T>> getAll({RestRequest? parameters}) async {

    // Cache hit?
    if (isMemoryCacheValid) {

      // Cache hit!
      return _memoryCache;
    }

    // Call the API
    var decodedBody = await _client.get(endpoint, request: parameters);
    var response = (decodedBody["data"] as List)
        .map((e) => factory.createFromJson(e))
        .toList();

    // Update the memory cache
    if (memoryCacheEnabled) {
      _memoryCache = response;
      _lastCacheTime = DateTime.now();
    }

    return response;
  }

  Future<T> add(Map<String, dynamic> data) async {
    var decodedBody =
        await _client.post(endpoint, data);
    return factory.createFromJson(decodedBody["data"]);
  }

  Future<T> update(String id, Map<String, dynamic> data) async {
    var decodedBody =
        await _client.put("$endpoint/$id", data);
    return factory.createFromJson(decodedBody["data"]);
  }


  /// **************************************************************************************************
  /// Cache
  /// **************************************************************************************************

  // Keep memory cache for a certain amount of time
  final Duration? memoryCacheDuration;

  // When the cache was last updated
  DateTime? _lastCacheTime;

  // Used to store the cache
  List<T> _memoryCache = [];

  // Whether the cache is enabled
  bool get memoryCacheEnabled => memoryCacheDuration != null;

  // When to hit the cache
  bool get isMemoryCacheValid {
    return memoryCacheEnabled &&
        _lastCacheTime != null &&
        DateTime.now().difference(_lastCacheTime!) < memoryCacheDuration!;
  }
}
