import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final class AudioCacheKey {
  const AudioCacheKey({
    required this.text,
    required this.voice,
    required this.rate,
    required this.engine,
  });

  final String text;
  final String voice;
  final double rate;
  final String engine;

  String get digest {
    final rateText = rate.isNaN ? 'nan' : rate.toStringAsFixed(2);
    final canonical = '$engine|$voice|$rateText|$text';
    return sha256.convert(utf8.encode(canonical)).toString();
  }
}

bool looksLikeWav(Uint8List bytes) {
  if (bytes.length < 12) return false;
  return bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x41 &&
      bytes[10] == 0x56 &&
      bytes[11] == 0x45;
}
