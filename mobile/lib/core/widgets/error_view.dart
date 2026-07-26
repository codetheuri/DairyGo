import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import 'primary_button.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  bool get _isNetworkError {
    final lower = message.toLowerCase();
    return lower.contains('internet') ||
        lower.contains('connection') ||
        lower.contains('offline') ||
        lower.contains('network');
  }

  @override
  Widget build(BuildContext context) {
    final isNetwork = _isNetworkError;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isNetwork ? AppColors.warning.withValues(alpha: 0.1) : AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 44,
                color: isNetwork ? AppColors.warning : AppColors.error,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isNetwork ? 'No Network Connection' : 'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
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
        ),
      ),
    );
  }
}
