import 'package:material_ui/material_ui.dart';

import '../../engine/game_world.dart';
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

    // 3. Draw Boundary Walls
    SpriteRenderer.drawWalls(
      canvas,
      world.worldWidth,
      world.worldHeight,
      world.wallThickness,
    );

    // 4. Draw Stations (Chai Kettle, Serving Counter, Trash Bin)
    SpriteRenderer.drawChaiStation(canvas, world.chaiStation);
    SpriteRenderer.drawServingCounter(canvas, world.counter);
    SpriteRenderer.drawTrashBin(canvas, world.trashBin);

    // 5. Draw Ground Cash Bundles
    for (final bundle in world.cashBundles) {
      SpriteRenderer.drawCashBundle(canvas, bundle);
    }

    // 6. Draw Player Character (with towering stack)
    SpriteRenderer.drawPlayer(canvas, world.player);

    // 7. Draw Floating "+Rs X" popups
    SpriteRenderer.drawFloatingTexts(canvas, world.floatingTexts);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WorldPainter oldDelegate) {
    return true; // Driven by the 60 FPS Ticker loop
  }
}
