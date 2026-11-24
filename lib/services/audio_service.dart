import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Audio playback service for sound effects and tactile haptic feedback (M7, M10).
class AudioService {
  bool isMuted = false;
  AudioPlayer? _hornPlayer;
  AudioPlayer? _brakePlayer;
  AudioPlayer? _doorOpenPlayer;
  AudioPlayer? _doorClosePlayer;

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

  /// Authentic dual-tone automotive car horn ("HONK HONK!")
  void playCarHorn() {
    if (isMuted) return;
    try {
      HapticFeedback.heavyImpact();
      _hornPlayer ??= AudioPlayer();
      _hornPlayer?.play(AssetSource('audio/car_horn.wav'), volume: 1.0);
    } catch (_) {}
  }

  /// Hydraulic brake pad friction & tire chirp
  void playCarBrake() {
    if (isMuted) return;
    try {
      HapticFeedback.mediumImpact();
      _brakePlayer ??= AudioPlayer();
      _brakePlayer?.play(AssetSource('audio/car_brake.wav'), volume: 0.85);
    } catch (_) {}
  }

  /// Sleek modern automatic sliding door opening sound (servo motor glide + air whoosh)
  void playDoorOpen() {
    if (isMuted) return;
    try {
      HapticFeedback.selectionClick();
      _doorOpenPlayer ??= AudioPlayer();
      _doorOpenPlayer?.play(AssetSource('audio/door_open.wav'), volume: 0.95);
    } catch (_) {}
  }

  /// Sleek modern automatic sliding door closing sound (descending glide + soft rubber seal)
  void playDoorClose() {
    if (isMuted) return;
    try {
      HapticFeedback.selectionClick();
      _doorClosePlayer ??= AudioPlayer();
      _doorClosePlayer?.play(AssetSource('audio/door_close.wav'), volume: 0.90);
    } catch (_) {}
  }

  /// Backward-compatible alias
  void playDoorSlide() => playDoorOpen();

  void dispose() {
    _hornPlayer?.dispose();
    _brakePlayer?.dispose();
    _doorOpenPlayer?.dispose();
    _doorClosePlayer?.dispose();
  }
}
