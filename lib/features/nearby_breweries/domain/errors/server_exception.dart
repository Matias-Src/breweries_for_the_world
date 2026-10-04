class ServerException implements Exception {
  const ServerException([this.message = 'The server returned an error.']);

  final String message;

  @override
  String toString() => message;
}
