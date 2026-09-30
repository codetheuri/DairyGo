import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Where the phone's back button leads from a main section.
enum BackTarget { more, home, exit }

/// Decides what back does on a main section's first screen, so it never
/// closes the app by surprise:
/// - a section opened from the More page goes back to More;
/// - any other section goes back to Home;
/// - Home asks for a second press before leaving the app.
BackTarget backTargetFor({required bool onHome, required bool openedFromMore}) {
  if (onHome) return BackTarget.exit;
  return openedFromMore ? BackTarget.more : BackTarget.home;
}

/// Handles the phone's back button for the main sections (see
/// [backTargetFor]). Screens pushed on top of a section are closed by the
/// navigator before this is asked.
class ShellBackHandler extends StatefulWidget {
  final bool onHome;
  final bool openedFromMore;
  final VoidCallback goHome;
  final VoidCallback goMore;
  final Widget child;

  /// Leaves the app; replaced in tests.
  final Future<void> Function() exitApp;

  const ShellBackHandler({
    super.key,
    required this.onHome,
    required this.openedFromMore,
    required this.goHome,
    required this.goMore,
    required this.child,
    this.exitApp = SystemNavigator.pop,
  });

  /// How long the "press back again" message counts a second press.
  static const exitWindow = Duration(seconds: 2);

  @override
  State<ShellBackHandler> createState() => _ShellBackHandlerState();
}

class _ShellBackHandlerState extends State<ShellBackHandler> {
  /// Runs while a second press on Home closes the app.
  Timer? _exitWindow;

  @override
  void dispose() {
    _exitWindow?.cancel();
    super.dispose();
  }

  void _onBack() {
    switch (backTargetFor(
      onHome: widget.onHome,
      openedFromMore: widget.openedFromMore,
    )) {
      case BackTarget.more:
        widget.goMore();
      case BackTarget.home:
        widget.goHome();
      case BackTarget.exit:
        if (_exitWindow?.isActive ?? false) {
          widget.exitApp();
          return;
        }
        _exitWindow = Timer(ShellBackHandler.exitWindow, () {});
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Press back again to close DairyGo'),
              duration: ShellBackHandler.exitWindow,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _onBack();
    },
    child: widget.child,
  );
}
