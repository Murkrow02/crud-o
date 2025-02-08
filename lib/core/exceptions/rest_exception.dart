class RestException implements Exception {
  final String message;
  final int code;

  RestException(this.message, this.code);

  @override
  String toString() {
    return "Rest request failed with code $code: $message";
  }
}