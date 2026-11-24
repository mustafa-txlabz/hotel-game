import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Audio playback service for sound effects and tactile haptic feedback (M7, M10, M12).
class AudioService {
  bool isMuted = false;
  bool isHapticsEnabled = true;

  AudioPlayer? _hornPlayer;
  AudioPlayer? _brakePlayer;
  AudioPlayer? _doorOpenPlayer;
  AudioPlayer? _doorClosePlayer;

  void triggerHaptic(void Function() hapticCall) {
    if (!isHapticsEnabled) return;
    try {
      hapticCall();
    } catch (_) {}
  }

  void playTap() {
    triggerHaptic(HapticFeedback.selectionClick);
    if (!isMuted) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void playBuy() {
    triggerHaptic(HapticFeedback.mediumImpact);
    if (!isMuted) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void playMilestone() {
    triggerHaptic(HapticFeedback.heavyImpact);
    if (!isMuted) {
      try {
        SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  void playSizzle() {
    triggerHaptic(HapticFeedback.lightImpact);
  }

  void playPour() {
    triggerHaptic(HapticFeedback.selectionClick);
  }

  void playServe() {
    triggerHaptic(HapticFeedback.lightImpact);
    if (!isMuted) {
      try {
        SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  void playCoin() {
    triggerHaptic(HapticFeedback.lightImpact);
  }

  /// Authentic dual-tone automotive car horn ("HONK HONK!")
  void playCarHorn() {
    triggerHaptic(HapticFeedback.heavyImpact);
    if (!isMuted) {
      try {
        _hornPlayer ??= AudioPlayer();
        _hornPlayer?.play(AssetSource('audio/car_horn.wav'), volume: 1.0);
      } catch (_) {}
    }
  }

  /// Hydraulic brake pad friction & tire chirp
  void playCarBrake() {
    triggerHaptic(HapticFeedback.mediumImpact);
    if (!isMuted) {
      try {
        _brakePlayer ??= AudioPlayer();
        _brakePlayer?.play(AssetSource('audio/car_brake.wav'), volume: 0.85);
      } catch (_) {}
    }
  }

  /// Door open/close sounds silenced per user request until custom sound asset is provided.
  void playDoorOpen() {}

  void playDoorClose() {}

  /// Backward-compatible alias
  void playDoorSlide() {}

  void dispose() {
    _hornPlayer?.dispose();
    _brakePlayer?.dispose();
    _doorOpenPlayer?.dispose();
    _doorClosePlayer?.dispose();
  }
}
