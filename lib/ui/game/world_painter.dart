import 'package:material_ui/material_ui.dart';

import '../../engine/customer_ai.dart';
import '../../engine/entities.dart';
import '../../engine/game_world.dart';
import '../../engine/staff_ai.dart';
import 'sprite_renderer.dart';

/// 60 FPS CustomPainter rendering the Dhaba world, stations, entities, cash bundles, and popups.
class WorldPainter extends CustomPainter {
  final GameWorld world;
  final Offset cameraOffset;

  WorldPainter({required this.world, required this.cameraOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Transform world coordinates relative to camera center
    canvas.save();
    canvas.translate(
      size.width / 2 - cameraOffset.dx,
      size.height / 2 - cameraOffset.dy,
    );

    // 2. Draw Floor
    SpriteRenderer.drawFloor(
      canvas,
      world.worldWidth,
      world.worldHeight,
      world.wallThickness,
    );

    // 3. Draw In-Place Machine Upgrade & Floor Unlock Pads (M4)
    for (final pad in world.groundPads) {
      SpriteRenderer.drawGroundPad(canvas, pad);
    }

    // 4. Draw Unlocked Dining Tables (M4)
    for (final table in world.diningTables) {
      SpriteRenderer.drawDiningTable(canvas, table);
    }

    // 5. Draw Boundary Walls
    SpriteRenderer.drawWalls(
      canvas,
      world.worldWidth,
      world.worldHeight,
      world.wallThickness,
    );

    // 6. Draw Stations (Chai Kettle, Serving Counter, Trash Bin)
    SpriteRenderer.drawChaiStation(canvas, world.chaiStation);
    SpriteRenderer.drawServingCounter(canvas, world.counter);
    SpriteRenderer.drawTrashBin(canvas, world.trashBin);

    // 7. Draw Ground Cash Bundles
    for (final bundle in world.cashBundles) {
      SpriteRenderer.drawCashBundle(canvas, bundle);
    }

    // 8. Draw Characters (Player, Customers, and Staff) sorted by Y-depth
    final characters = <dynamic>[
      world.player,
      ...world.customerSystem.activeCustomers,
      ...world.staff,
    ]..sort((a, b) => a.position.y.compareTo(b.position.y));

    for (final char in characters) {
      if (char is PlayerEntity) {
        SpriteRenderer.drawPlayer(canvas, char);
      } else if (char is CustomerEntity) {
        SpriteRenderer.drawCustomer(canvas, char);
      } else if (char is StaffEntity) {
        if (char.role == StaffRole.cashier) {
          SpriteRenderer.drawCashier(canvas, char);
        } else {
          SpriteRenderer.drawHelper(canvas, char);
        }
      }
    }

    // 9. Draw Floating "+Rs X" popups
    SpriteRenderer.drawFloatingTexts(canvas, world.floatingTexts);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WorldPainter oldDelegate) {
    return true; // Driven by the 60 FPS Ticker loop
  }
}
