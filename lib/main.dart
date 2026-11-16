import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Support portrait only as per design specifications
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ChaiDhabaEmpireApp());
}
