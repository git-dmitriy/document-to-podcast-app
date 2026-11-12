final class VoiceByteStream {
  const VoiceByteStream({
    required this.statusCode,
    required this.totalBytes,
    required this.bytes,
  });

  final int statusCode;
  final int? totalBytes;
  final Stream<List<int>> bytes;
}

abstract interface class VoiceFileSource {
  Future<VoiceByteStream> open(Uri url, {int fromByte = 0});
}

int? voiceContentTotal({
  required int statusCode,
  required int contentLength,
  required String? contentRange,
  required int fromByte,
}) {
  if (statusCode == 206) {
    final range = contentRange;
    if (range != null) {
      final slash = range.lastIndexOf('/');
      if (slash >= 0 && slash < range.length - 1) {
        final total = int.tryParse(range.substring(slash + 1).trim());
        if (total != null && total >= 0) return total;
      }
    }
    if (contentLength >= 0) return fromByte + contentLength;
    return null;
  }
  if (contentLength >= 0) return contentLength;
  return null;
}
