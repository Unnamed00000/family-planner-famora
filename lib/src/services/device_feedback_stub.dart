import 'package:flutter/services.dart';

void playTapFeedback({
  required bool soundEnabled,
  required bool vibrationEnabled,
}) {
  if (soundEnabled) {
    SystemSound.play(SystemSoundType.click);
  }
  if (vibrationEnabled) {
    HapticFeedback.selectionClick();
  }
}
