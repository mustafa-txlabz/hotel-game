import 'dart:math' as math;
import 'dart:ui';

import 'entities.dart';
import 'stations.dart';

/// Models of luxury cars arriving at the Dhaba.
enum CarModel {
  sedan,
  suv,
  vintage,
}

/// Travel direction on the two-way GT Highway.
enum CarDirection {
  /// Driving from Left (West) towards Right (East)
  eastBound,

  /// Driving from Right (East) towards Left (West)
  westBound,
}

/// State machine for VVIP luxury cars.
enum CarState {
  drivingIn,
  parkedWaitingOrder,
  drivingOut,
  despawned,
}

/// Represents a VVIP customer luxury car on the GT Highway.
class VipCar {
  final int id;
  final CarModel model;
  final CarDirection direction;
  final Color color;
  final Vector2 position;
  final Vector2 targetParkPosition;

  final double width;
  final double height;
  double speed;
  CarState state;

  // Bulk order details
  final int desiredChai;
  final int desiredParatha;
  int receivedChai;
  int receivedParatha;

  // Patience timer (15 seconds per item, resets to 0 upon every item loaded)
  double patienceTime;
  double patienceTimer;

  // Rewards
  final int gemsReward;
  final double cashTip;

  VipCar({
    required this.id,
    required this.model,
    required this.direction,
    required this.color,
    required Vector2 startPosition,
    required this.targetParkPosition,
    this.desiredChai = 15,
    this.desiredParatha = 15,
    this.patienceTime = 15.0,
    this.gemsReward = 3,
    this.cashTip = 1000.0,
  })  : position = startPosition.copy(),
        receivedChai = 0,
        receivedParatha = 0,
        patienceTimer = 0.0,
        speed = 220.0,
        state = CarState.drivingIn,
        width = model == CarModel.suv
            ? 160.0
            : (model == CarModel.vintage ? 146.0 : 152.0),
        height = model == CarModel.suv ? 76.0 : 70.0;

  int get totalDesired => desiredChai + desiredParatha;
  int get totalReceived => receivedChai + receivedParatha;
  int get remainingChai => desiredChai - receivedChai;
  int get remainingParatha => desiredParatha - receivedParatha;
  int get totalRemaining => remainingChai + remainingParatha;
  bool get isOrderComplete => totalRemaining <= 0;

  double get progress =>
      totalDesired > 0 ? (totalReceived / totalDesired).clamp(0.0, 1.0) : 1.0;

  /// Physical bounding box for solid collision with characters.
  Rect get collisionBox => Rect.fromCenter(
        center: Offset(position.x, position.y),
        width: width,
        height: height,
      );

  /// Drop zone on the sidewalk next to the car where player/helpers unload items.
  Rect get curbsideDropZone => Rect.fromCenter(
        center: Offset(position.x, 1260.0), // Sidewalk curb edge
        width: width * 0.85,
        height: 48.0,
      );

  bool isInsideDropZone(Vector2 pos) {
    return curbsideDropZone.contains(Offset(pos.x, pos.y));
  }

  /// Loads an item into the car and RESETS the 15s patience timer!
  bool receiveItem(ItemType item) {
    if (item == ItemType.chai && receivedChai < desiredChai) {
      receivedChai++;
      patienceTimer = 0.0; // Reset patience upon item delivery!
      return true;
    } else if (item == ItemType.paratha && receivedParatha < desiredParatha) {
      receivedParatha++;
      patienceTimer = 0.0; // Reset patience upon item delivery!
      return true;
    }
    return false;
  }

  /// Updates car movement, state, and patience.
  void update(double dt) {
    if (state == CarState.despawned) return;

    if (state == CarState.drivingIn) {
      final dx = targetParkPosition.x - position.x;
      final step = speed * dt;
      if (dx.abs() <= step || dx.abs() <= 6.0) {
        position.x = targetParkPosition.x;
        state = CarState.parkedWaitingOrder;
      } else {
        position.x += (dx > 0 ? 1 : -1) * step;
      }
    } else if (state == CarState.parkedWaitingOrder) {
      // Patience timer advances while parked waiting for food
      patienceTimer += dt;
    } else if (state == CarState.drivingOut) {
      // Drives forward in same travel direction
      final dirSign = direction == CarDirection.eastBound ? 1 : -1;
      position.x += dirSign * (speed * 1.3) * dt;

      // Despawn when far off-screen
      if (position.x < -300.0 || position.x > 1300.0) {
        state = CarState.despawned;
      }
    }
  }

  /// Palette of vibrant Burger Please! inspired candy colors for luxury cars.
  static const List<Color> vibrantColors = [
    Color(0xFFE53935), // Crimson Red
    Color(0xFF1E88E5), // Royal Sapphire Blue
    Color(0xFFFFB300), // Golden Saffron
    Color(0xFF8E24AA), // Cyber Purple
    Color(0xFF212121), // Midnight Executive Black
    Color(0xFF00897B), // Mint Emerald Green
  ];

  /// Random generator helper.
  static VipCar createRandom({
    required int id,
    CarDirection? forcedDirection,
    CarModel? forcedModel,
    Color? forcedColor,
  }) {
    final rand = math.Random();
    final dir = forcedDirection ??
        (rand.nextBool() ? CarDirection.eastBound : CarDirection.westBound);
    final model = forcedModel ??
        CarModel.values[rand.nextInt(CarModel.values.length)];
    final color = forcedColor ??
        vibrantColors[rand.nextInt(vibrantColors.length)];

    // Target parking position at the North GT Road lane directly fronting the Dhaba entrance
    final targetPark = Vector2(450.0, 1360.0);

    // Start position depends on travel direction
    final startX = dir == CarDirection.eastBound ? -180.0 : 1080.0;
    final startPos = Vector2(startX, 1360.0);

    // Random bulk order between 24 and 36 items
    final chaiCount = 12 + rand.nextInt(7); // 12 to 18
    final parathaCount = 12 + rand.nextInt(7); // 12 to 18

    return VipCar(
      id: id,
      model: model,
      direction: dir,
      color: color,
      startPosition: startPos,
      targetParkPosition: targetPark,
      desiredChai: chaiCount,
      desiredParatha: parathaCount,
      patienceTime: 15.0,
      gemsReward: 3,
      cashTip: 1000.0,
    );
  }
}
