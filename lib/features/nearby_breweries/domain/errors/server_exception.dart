class ServerException implements Exception {
  const ServerException([
    this.message = 'The server returned an error.',
    this.statusCode,
    this.cause,
  ]);

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => message;
}
