
class ApiValidationException implements Exception {
  final Map<String, List<String>> errors;
  ApiValidationException(this.errors);

  @override
  String toString() {
    var errorsString = errors.entries
        .map((entry) => '${entry.key}: ${entry.value.join(', ')}')
        .join('\n');

    return 'ApiValidationException: $errorsString';
  }
}
