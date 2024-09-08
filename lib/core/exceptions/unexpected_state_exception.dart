class UnexpectedStateException implements Exception {

  final dynamic state;
  UnexpectedStateException(this.state);

  @override
  String toString() {
    return 'UnexpectedStateException: $state';
  }
}