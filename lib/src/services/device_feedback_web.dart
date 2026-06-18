// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:js' as js;

import 'package:flutter/services.dart';

void playTapFeedback({
  required bool soundEnabled,
  required bool vibrationEnabled,
}) {
  if (soundEnabled) {
    SystemSound.play(SystemSoundType.click);
  }
  if (vibrationEnabled) {
    js.context['navigator']?.callMethod('vibrate', [35]);
  }
}
