import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../network/connection_monitor.dart';

/// Covers a screen while something is being saved: dims it, blocks taps (so
/// a form cannot be changed or submitted twice mid-save), and shows
/// [message]. On a slow connection it also asks the user to wait and keep
/// the app open; the save completes once, even if it has to be retried.
class LoadingOverlay extends ConsumerWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slow = ref.watch(connectionMonitorProvider.select((s) => s.isSlow));

    return Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black26),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Card(
              margin: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (slow) ...[
                      const SizedBox(height: 8),
                      Text(
                        'The connection is slow. Please wait and keep the app '
                        'open; it will only be saved once.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
