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
      js.context.callMethod('eval', [_clickSoundScript]);
    } catch (_) {
      // Some browsers block web audio or system click sounds. Keep the tap working.
    }
  }

  if (vibrationEnabled) {
    HapticFeedback.selectionClick();
    try {
      final navigator = js.context['navigator'];
      if (navigator != null && navigator.hasProperty('vibrate')) {
        navigator.callMethod('vibrate', [35]);
      }
    } catch (_) {
      // iPhone/iOS Safari usually does not support web vibration.
      // Keep the tap working.
    }
  }
}

const _clickSoundScript = r'''
(function () {
  try {
    var AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;

    window.__famoraAudioContext = window.__famoraAudioContext || new AudioContext();
    var ctx = window.__famoraAudioContext;

    if (ctx.state === 'suspended') {
      ctx.resume();
    }

    var now = ctx.currentTime;
    var oscillator = ctx.createOscillator();
    var gain = ctx.createGain();

    oscillator.type = 'square';
    oscillator.frequency.value = 650;

    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.025, now + 0.005);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.045);

    oscillator.connect(gain);
    gain.connect(ctx.destination);

    oscillator.start(now);
    oscillator.stop(now + 0.05);
  } catch (e) {}
})();
''';
