// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:js' as js;

import 'package:flutter/services.dart';

void playTapFeedback({
  required bool soundEnabled,
  required bool vibrationEnabled,
}) {
  if (soundEnabled) {
    try {
      SystemSound.play(SystemSoundType.click).catchError((_) {});
    } catch (_) {
      // Some browsers/devices do not support system click sounds.
    }
  }

  if (vibrationEnabled) {
    try {
      final navigator = js.context['navigator'];
      if (navigator != null && navigator.hasProperty('vibrate')) {
        navigator.callMethod('vibrate', [35]);
      }
    } catch (_) {
      // iPhone/iOS Safari does not support the Vibration API.
      // Ignore the error so taps still switch tabs normally.
    }
  }
}
