import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import 'primary_button.dart';

enum _ErrorKind { noAccess, network, other }

/// Shows why something could not be loaded, in one of three forms:
/// - no access (the user's role may not see this): a lock and an explanation,
///   without Retry, because retrying cannot help;
/// - network (no internet, slow connection): with Retry;
/// - anything else: the server's message, with Retry.
///
/// It stays where it is; it never closes the screen on its own, because it
/// is often one section of a screen, and closing the whole screen after a
/// moment would lose the user's place.
class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({super.key, required this.message, required this.onRetry});

  _ErrorKind get _kind {
    final lower = message.toLowerCase();
    if (lower.contains('forbidden') ||
        lower.contains('insufficient permissions')) {
      return _ErrorKind.noAccess;
    }
    if (lower.contains('internet') ||
        lower.contains('connection') ||
        lower.contains('offline') ||
        lower.contains('network') ||
        lower.contains('too slow')) {
      return _ErrorKind.network;
    }
    return _ErrorKind.other;
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kind;
    final (icon, color, background, title, text) = switch (kind) {
      _ErrorKind.noAccess => (
        Icons.lock_outline_rounded,
        AppColors.warning,
        AppColors.warning.withValues(alpha: 0.1),
        'No access',
        'Your role does not include this. Ask your Sacco admin if you need it.',
      ),
      _ErrorKind.network => (
        Icons.cloud_off_rounded,
        AppColors.warning,
        AppColors.warning.withValues(alpha: 0.1),
        'Could not connect',
        message,
      ),
      _ErrorKind.other => (
        Icons.error_outline_rounded,
        AppColors.error,
        AppColors.errorContainer,
        'Something went wrong',
        message,
      ),
    };

    return Center(
      // Scrolls when shown in a small section or with large text.
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            if (kind != _ErrorKind.noAccess) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                child: PrimaryButton(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
