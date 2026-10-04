class NetworkException implements Exception {
  const NetworkException([this.message = 'A network error occurred.']);

  final String message;

  @override
  String toString() => message;
}
