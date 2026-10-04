class NetworkException implements Exception {
  const NetworkException([
    this.message = 'A network error occurred.',
    this.cause,
  ]);

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
