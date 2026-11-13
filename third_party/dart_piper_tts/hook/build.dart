import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_rust/native_toolchain_rust.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final code = input.config.code;

    // Upstream already skips Intel macOS: ort has no prebuilt binaries there.
    // The same is true for Android armeabi-v7a and x86_64.
    // Flutter's default `flutter build apk --release` still asks hooks to build
    // those ABIs; skip them and ship arm64-only via app abiFilters.
    if (_ortUnsupported(code)) {
      stdout.writeln(
        'Skipping ${code.targetOS} ${code.targetArchitecture}: '
        'ort has no prebuilt binaries for this target',
      );
      return;
    }

    final ndkHome = _androidNdkHome(code);
    await RustBuilder(
      assetName: 'src/ffi.g.dart',
      extraCargoEnvironmentVariables: {
        if (ndkHome != null) ...{
          'ANDROID_NDK_HOME': ndkHome,
          'ANDROID_NDK_ROOT': ndkHome,
        },
      },
    ).run(input: input, output: output);
  });
}

bool _ortUnsupported(CodeConfig code) {
  if (code.targetOS == OS.macOS &&
      code.targetArchitecture == Architecture.x64) {
    return true;
  }
  if (code.targetOS == OS.android &&
      code.targetArchitecture != Architecture.arm64) {
    return true;
  }
  return false;
}

/// `dart_piper_tts` rust/build.rs requires ANDROID_NDK_HOME, but Flutter hooks
/// only pass the NDK clang path. Derive the NDK root from that compiler path.
String? _androidNdkHome(CodeConfig code) {
  final fromEnv =
      Platform.environment['ANDROID_NDK_HOME'] ??
      Platform.environment['ANDROID_NDK_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return fromEnv;
  }
  if (code.targetOS != OS.android) {
    return null;
  }

  final compiler = code.cCompiler?.compiler;
  if (compiler == null) {
    return null;
  }

  final filePath = compiler.toFilePath();
  final marker = '${Platform.pathSeparator}ndk${Platform.pathSeparator}';
  final index = filePath.indexOf(marker);
  if (index < 0) {
    return null;
  }

  final afterNdk = filePath.substring(index + marker.length);
  final version = afterNdk.split(Platform.pathSeparator).first;
  if (version.isEmpty) {
    return null;
  }
  return '${filePath.substring(0, index + marker.length)}$version';
}
