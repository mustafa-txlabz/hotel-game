import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'state/game_controller.dart';
import 'ui/screens/splash_screen.dart';

/// Global RouteObserver for screen navigation and banner refresh awareness.
final RouteObserver<ModalRoute<void>> appRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// Root game application widget.
class ChaiDhabaEmpireApp extends StatelessWidget {
  final Widget? home;

  const ChaiDhabaEmpireApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GameController>(
      create: (_) => GameController(),
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorObservers: [appRouteObserver],
        home: home ?? const SplashScreen(),
      ),
    );
  }
}
