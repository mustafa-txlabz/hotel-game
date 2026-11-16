import 'package:material_ui/material_ui.dart';

import '../../engine/game_world.dart';
import 'sprite_renderer.dart';

/// 60 FPS CustomPainter rendering the Dhaba world, walls, floor, and entities.
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

    // 4. Draw Player Character
    SpriteRenderer.drawPlayer(canvas, world.player);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WorldPainter oldDelegate) {
    return true; // Continuously repaints driven by the 60 FPS Ticker
  }
}
