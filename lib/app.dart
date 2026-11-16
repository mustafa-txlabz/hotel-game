import 'package:material_ui/material_ui.dart';
import 'core/strings.dart';
import 'core/theme.dart';
import 'ui/screens/home_placeholder_screen.dart';

/// Root game application widget.
class ChaiDhabaEmpireApp extends StatelessWidget {
  const ChaiDhabaEmpireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomePlaceholderScreen(),
    );
  }
}
