
class ApiValidationException implements Exception {
  final Map<String, List<dynamic>> errors;
  ApiValidationException(this.errors);
}
