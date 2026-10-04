class ParsingException implements Exception {
  const ParsingException([this.message = 'The brewery response was invalid.']);

  final String message;

  @override
  String toString() => message;
}
