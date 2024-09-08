import 'package:crud_o/core/networking/rest/requests/paginated_request.dart';
import 'package:crud_o/core/networking/rest/rest_client.dart';
import 'package:crud_o/core/networking/rest/responses/paginated_response.dart';
import 'package:crud_o/resources/resource.dart';
import 'package:crud_o/resources/resource_factory.dart';

class ResourceClient<T> extends RestClient {

  final ResourceFactory<T> resourceFactory;
  ResourceClient(this.resourceFactory);

  
  Future<PaginatedResourceResponse<T>> getPaginated(String endpoint, {PaginatedRequest? request}) async {
    
    // Normal get operation
    var decodedBody = await get(endpoint, request: request);

    // Create paginated response object
    PaginatedResourceResponse<T> restResponse = PaginatedResourceResponse<T>.fromJson(decodedBody);

    // Deserialize data as a list
    restResponse.data = (decodedBody["data"] as List).map((e) => resourceFactory.createFromJson(e)).toList();

    return restResponse;
  }





}
