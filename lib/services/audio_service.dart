import 'package:flutter/services.dart';

/// Audio playback service for sound effects and tactile haptic feedback (M7).
class AudioService {
  bool isMuted = false;

  void playTap() {
    if (isMuted) return;
    try {
      HapticFeedback.selectionClick();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playBuy() {
    if (isMuted) return;
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playMilestone() {
    if (isMuted) return;
    try {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }

  void playSizzle() {
    if (isMuted) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void playPour() {
    if (isMuted) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  void playServe() {
    if (isMuted) return;
    try {
      HapticFeedback.lightImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  void playCoin() {
    if (isMuted) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }
}
