import 'dart:math';

final documentIdPattern = RegExp(r'^[a-zA-Z0-9_-]{1,80}$');

String defaultDocumentId() {
  final now = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(16);
  final salt = Random().nextInt(0x7fffffff).toRadixString(16);
  return '$now-$salt';
}
