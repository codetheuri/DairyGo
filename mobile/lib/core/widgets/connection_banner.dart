import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/theme/app_colors.dart';
import '../network/connection_monitor.dart';

/// Shows the state of the connection under [child]:
/// - no internet: when the data on screen is from, and that saving needs a
///   connection, with a Retry button;
/// - slow: that loading and saving may take longer;
/// - back online: a short confirmation.
/// Nothing is shown while the connection is fine.
class ConnectionBanner extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectionBanner({super.key, required this.child});

  @override
  ConsumerState<ConnectionBanner> createState() => _ConnectionBannerState();
}

enum _Shown { none, offline, slow, backOnline }

class _ConnectionBannerState extends ConsumerState<ConnectionBanner> {
  bool _backOnline = false;
  bool _checking = false;
  Timer? _backOnlineTimer;

  @override
  void dispose() {
    _backOnlineTimer?.cancel();
    super.dispose();
  }

  Future<void> _retry() async {
    setState(() => _checking = true);
    await ref.read(connectionMonitorProvider.notifier).checkNow();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(connectionMonitorProvider, (previous, next) {
      if (previous?.isOffline == true && !next.isOffline) {
        setState(() => _backOnline = true);
        _backOnlineTimer?.cancel();
        _backOnlineTimer = Timer(const Duration(seconds: 3), () {
          if (mounted) setState(() => _backOnline = false);
        });
      }
    });
    final status = ref.watch(connectionMonitorProvider);
    final shown = status.isOffline
        ? _Shown.offline
        : status.isSlow
        ? _Shown.slow
        : _backOnline
        ? _Shown.backOnline
        : _Shown.none;

    // The banner sits at the very bottom of the app, so it keeps clear of
    // the gesture bar itself, and the screen above stops reserving that
    // space while it shows.
    final showing = shown != _Shown.none;
    // Painted behind everything, so the strip's resize and fade never show
    // an unpainted (black) gap at the root of the app.
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: showing
                ? MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: widget.child,
                  )
                : widget.child,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (shown) {
                _Shown.none => const SizedBox(width: double.infinity),
                _Shown.offline => _Strip(
                  key: const ValueKey('offline'),
                  color: AppColors.textPrimary,
                  icon: Icons.cloud_off_rounded,
                  title: 'No internet connection',
                  subtitle: _offlineSubtitle(status.lastOnlineAt),
                  action: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : TextButton(
                          onPressed: _retry,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            minimumSize: const Size(64, 36),
                          ),
                          child: const Text('Retry'),
                        ),
                ),
                _Shown.slow => const _Strip(
                  key: ValueKey('slow'),
                  color: AppColors.warning,
                  icon: Icons.network_check_rounded,
                  title: 'Slow connection',
                  subtitle: 'Loading and saving may take a little longer.',
                ),
                _Shown.backOnline => const _Strip(
                  key: ValueKey('online'),
                  color: AppColors.success,
                  icon: Icons.wifi_rounded,
                  title: 'Back online',
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _offlineSubtitle(DateTime? lastOnlineAt) {
    final since = lastOnlineAt == null
        ? 'Showing saved data'
        : 'Showing data from ${DateFormat.jm().format(lastOnlineAt)}';
    return '$since · saving needs a connection';
  }
}

class _Strip extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const _Strip({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    // Kept compact like the bottom bar: the text barely grows with the
    // phone's font setting, so the strip never covers much of the screen.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Semantics(
        liveRegion: true,
        child: Material(
          color: color,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (action != null) ...[const SizedBox(width: 8), action!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
