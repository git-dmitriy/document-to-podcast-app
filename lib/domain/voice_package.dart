import 'app_language.dart';

enum VoiceId { irina, lessac }

final class VoiceFile {
  const VoiceFile({required this.name, required this.url});

  final String name;
  final Uri url;
}

final class VoicePackage {
  const VoicePackage({
    required this.id,
    required this.language,
    required this.title,
    required this.files,
  });

  final VoiceId id;
  final AppLanguage language;
  final String title;
  final List<VoiceFile> files;

  String get languageLabel => switch (language) {
    AppLanguage.ru => 'Russian · ru-RU',
    AppLanguage.en => 'English · en-US',
  };
}

const piperVoicesCommit = 'ae9d8352b73c1b1750748843e753a504b00e05b0';

final voiceCatalog = <VoicePackage>[
  VoicePackage(
    id: VoiceId.irina,
    language: AppLanguage.ru,
    title: 'Irina',
    files: [
      VoiceFile(
        name: 'ru_RU-irina-medium.onnx',
        url: Uri.parse(
          'https://huggingface.co/rhasspy/piper-voices/resolve/$piperVoicesCommit/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx',
        ),
      ),
      VoiceFile(
        name: 'ru_RU-irina-medium.onnx.json',
        url: Uri.parse(
          'https://huggingface.co/rhasspy/piper-voices/resolve/$piperVoicesCommit/ru/ru_RU/irina/medium/ru_RU-irina-medium.onnx.json',
        ),
      ),
    ],
  ),
  VoicePackage(
    id: VoiceId.lessac,
    language: AppLanguage.en,
    title: 'Lessac',
    files: [
      VoiceFile(
        name: 'en_US-lessac-medium.onnx',
        url: Uri.parse(
          'https://huggingface.co/rhasspy/piper-voices/resolve/$piperVoicesCommit/en/en_US/lessac/medium/en_US-lessac-medium.onnx',
        ),
      ),
      VoiceFile(
        name: 'en_US-lessac-medium.onnx.json',
        url: Uri.parse(
          'https://huggingface.co/rhasspy/piper-voices/resolve/$piperVoicesCommit/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json',
        ),
      ),
    ],
  ),
];

VoicePackage voiceById(VoiceId id) {
  for (final voice in voiceCatalog) {
    if (voice.id == id) return voice;
  }
  throw ArgumentError.value(id, 'id', 'Unknown voice.');
}
