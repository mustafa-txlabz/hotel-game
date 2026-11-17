/// Central gameplay balance constants and upgrade curves.
class GameBalance {
  // Player Stats
  static const double playerBaseSpeed = 220.0;
  static const int playerBaseCapacity = 3;

  // Dhaba World Arena
  static const double worldWidth = 900.0;
  static const double worldHeight = 1200.0;
  static const double wallThickness = 32.0;

  // Camera Settings
  static const double cameraLerpFactor = 0.12;

  // Virtual Joystick
  static const double joystickRadius = 60.0;
  static const double knobRadius = 26.0;

  // Customer & Economy Settings (M3)
  static const double customerSpeed = 135.0;
  static const double customerSpawnInterval = 3.2;
  static const int maxQueueCapacity = 5;
  static const double customerPatienceTime = 22.0;
  static const double chaiPrice = 10.0;
}
