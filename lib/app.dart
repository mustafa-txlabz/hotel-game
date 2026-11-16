import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'state/game_controller.dart';
import 'ui/screens/dhaba_screen.dart';

/// Root game application widget.
class ChaiDhabaEmpireApp extends StatelessWidget {
  const ChaiDhabaEmpireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameController>(
      create: (_) => GameController(),
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const DhabaScreen(),
      ),
    );
  }
}
