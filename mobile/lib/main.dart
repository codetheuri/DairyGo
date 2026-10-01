import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/network/connection_monitor.dart';
import 'core/widgets/connection_banner.dart';
import 'features/app_update/presentation/app_update_controller.dart';
import 'features/app_update/presentation/widgets/update_gate.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DairySaccoApp()));
}

class DairySaccoApp extends ConsumerStatefulWidget {
  const DairySaccoApp({super.key});

  @override
  ConsumerState<DairySaccoApp> createState() => _DairySaccoAppState();
}

class _DairySaccoAppState extends ConsumerState<DairySaccoApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Coming back to the app: sign out if it sat unused past the idle limit,
    // and re-check a connection that was down.
    _lifecycle = AppLifecycleListener(
      onResume: () {
        ref.read(authControllerProvider.notifier).checkIdleSession();
        final monitor = ref.read(connectionMonitorProvider.notifier);
        if (monitor.current.isOffline) monitor.checkNow();
        ref.read(appUpdateProvider.notifier).onResume();
      },
    );
    // Look for a new version once the first screen is up.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(appUpdateProvider.notifier).check(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DairyGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      // Follow the phone's font-size setting, but only up to 1.3x: beyond that
      // the dense field screens stop fitting on a phone. The connection banner
      // and the update strip cover every screen, forms and login included;
      // an app too old to use shows only the update screen.
      //
      // Android draws apps behind its navigation bar (the back, home and
      // recent buttons). Keeping everything above it here, once, means no
      // screen, sheet or dialog can put a button under those keys; the strip
      // behind the bar is white, like the bottom menu and the sheets.
      builder: (context, child) => ColoredBox(
        color: Colors.white,
        child: SafeArea(
          top: false,
          left: false,
          right: false,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: UpdateGate(child: ConnectionBanner(child: child!)),
          ),
        ),
      ),
    );
  }
}
