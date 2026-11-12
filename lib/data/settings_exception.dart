final class SettingsException implements Exception {
  const SettingsException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    final cause = this.cause;
    if (cause == null) return message;
    return '$message ($cause)';
  }
}
