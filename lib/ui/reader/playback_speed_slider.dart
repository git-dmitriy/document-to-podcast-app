import 'dart:async';

import 'package:flutter/material.dart';

import '../settings/settings_controller.dart';
import 'playback_controller.dart';

class PlaybackSpeedSlider extends StatelessWidget {
  const PlaybackSpeedSlider({
    required this.playback,
    required this.settings,
    super.key,
  });

  final PlaybackController playback;
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: playback.rate,
      min: PlaybackController.minRate,
      max: PlaybackController.maxRate,
      onChanged: (value) {
        unawaited(playback.setRate(value));
      },
      onChangeEnd: (value) {
        unawaited(settings.setRate(value));
      },
    );
  }
}
