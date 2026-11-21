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

  // Customer & Economy Settings (M3 & M5)
  static const double customerSpeed = 135.0;
  static const double customerSpawnInterval = 4.0;
  static const int maxQueueCapacity = 8;
  static const double customerPatienceTime = 22.0;
  static const double chaiPrice = 10.0;
  static const double customerEatDuration = 5.0;
  static const double dineInTip = 25.0;
  static const int maxCustomerOrderItems = 10;
  static const int maxDineInOrderItems = 3;
  static const double customerTableWaitDuration = 2.5;

  // Staff Hiring & HR Upgrades (M6)
  static const int maxWorkersLevel1 = 3;
  static const double hireCashierCost = 150.0;
  static const double hireHelperBaseCost = 200.0;
  static const double hireHelperCostMultiplier = 1.6;
  static const double hireChotuBaseCost = hireHelperBaseCost;
  static const double hireChotuCostMultiplier = hireHelperCostMultiplier;

  // Owner Upgrades
  static const List<double> playerSpeedLevels = [220.0, 255.0, 290.0, 330.0, 370.0];
  static const List<double> playerSpeedUpgradeCosts = [60.0, 120.0, 200.0, 320.0];

  static const List<int> playerCapacityLevels = [3, 5, 8, 12, 16];
  static const List<double> playerCapacityUpgradeCosts = [80.0, 150.0, 250.0, 400.0];

  // Worker / Helper Stats & Upgrades
  static const double workerBaseSpeed = 150.0;
  static const int workerBaseCapacity = 2;

  static const List<double> workerSpeedLevels = [150.0, 185.0, 220.0, 260.0];
  static const List<double> workerSpeedUpgradeCosts = [75.0, 140.0, 240.0];

  static const List<int> workerCapacityLevels = [2, 3, 5, 8];
  static const List<double> workerCapacityUpgradeCosts = [90.0, 180.0, 300.0];
}
