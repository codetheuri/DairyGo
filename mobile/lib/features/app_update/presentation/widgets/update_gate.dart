import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../app_update_controller.dart';

/// What the update area says and offers in the current step.
class UpdateStatus {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// 0..1 while downloading (null before the size is known).
  final double? progress;
  final bool downloading;
  final bool isError;

  /// The strip offers "Later" (only for an offer, not work under way).
  final bool canPutOff;

  const UpdateStatus({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.progress,
    this.downloading = false,
    this.isError = false,
    this.canPutOff = false,
  });

  static String _mb(int bytes) => (bytes / (1 << 20)).toStringAsFixed(0);

  /// The status for [s]; null when there is nothing to update.
  static UpdateStatus? of(AppUpdateState s, AppUpdateController c) {
    final latest = s.latest;
    if (!s.available || latest == null) return null;
    final size = latest.files[s.abi]?.size ?? 0;
    return switch (s.step) {
      UpdateStep.idle => UpdateStatus(
        icon: Icons.system_update_rounded,
        title: 'New version ${latest.version} is ready',
        subtitle: '${_mb(size)} MB · Wi-Fi is best on a slow connection',
        actionLabel: 'Update',
        onAction: c.update,
        canPutOff: true,
      ),
      UpdateStep.downloading => UpdateStatus(
        icon: Icons.downloading_rounded,
        title: 'Downloading update… ${((s.progress ?? 0) * 100).floor()}%',
        subtitle:
            '${_mb(s.received)} of ${_mb(s.total)} MB · you can keep '
            'using the app',
        actionLabel: 'Stop',
        onAction: c.cancel,
        progress: s.progress,
        downloading: true,
      ),
      UpdateStep.needsPermission => UpdateStatus(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Allow DairyGo to install the update',
        subtitle:
            'Turn on "Allow from this source", then press Back to '
            'return here.',
        actionLabel: 'Allow',
        onAction: c.allowInstalls,
      ),
      UpdateStep.readyToInstall => UpdateStatus(
        icon: Icons.restart_alt_rounded,
        title: 'Version ${latest.version} is ready to install',
        subtitle: 'Tap Restart: DairyGo closes and opens again, updated.',
        actionLabel: 'Restart',
        onAction: c.install,
        canPutOff: true,
      ),
      UpdateStep.installing => UpdateStatus(
        icon: Icons.install_mobile_rounded,
        title: 'Updating DairyGo…',
        subtitle:
            'The app closes and opens again. If Android asks, tap Update. '
            'If it stays closed, open DairyGo from its icon.',
        actionLabel: 'Restart',
        onAction: c.install,
      ),
      UpdateStep.failed => UpdateStatus(
        icon: Icons.error_outline_rounded,
        title: 'Update not finished',
        subtitle: s.error,
        actionLabel: 'Try again',
        onAction: c.update,
        isError: true,
      ),
    };
  }
}

/// Wraps the whole app:
/// - when this version is no longer allowed, shows only the update screen;
/// - when a newer version is ready, a strip at the bottom offers it.
class UpdateGate extends ConsumerWidget {
  final Widget child;

  const UpdateGate({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    if (state.required) return const UpdateRequiredScreen();

    final status = UpdateStatus.of(state, ref.read(appUpdateProvider.notifier));
    // A download on Wi-Fi shows only once it is ready; "Later" hides an
    // offer, never work under way.
    final show =
        status != null &&
        !(state.quiet && state.step == UpdateStep.downloading) &&
        !(state.dismissed && status.canPutOff);
    return ColoredBox(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: show
                ? MediaQuery.removePadding(
                    context: context,
                    removeBottom: true,
                    child: child,
                  )
                : child,
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: show
                ? _UpdateStrip(status: status)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _UpdateStrip extends ConsumerWidget {
  final UpdateStatus status;

  const _UpdateStrip({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = status.isError ? AppColors.error : AppColors.primary;
    return Material(
      color: color,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(status.icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (status.subtitle != null)
                          Text(
                            status.subtitle!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              // Buttons on their own line, so they fit the smallest phones
              // with large text.
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 4,
                  children: [
                    if (status.canPutOff)
                      TextButton(
                        onPressed: ref.read(appUpdateProvider.notifier).later,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          minimumSize: const Size(48, 40),
                        ),
                        child: const Text('Later'),
                      ),
                    if (status.actionLabel != null)
                      FilledButton(
                        onPressed: status.onAction,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: color,
                          minimumSize: const Size(64, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: Text(status.actionLabel!),
                      ),
                  ],
                ),
              ),
              if (status.downloading) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: status.progress,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown instead of the app when this version is no longer allowed.
class UpdateRequiredScreen extends ConsumerWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    final controller = ref.read(appUpdateProvider.notifier);
    final status = UpdateStatus.of(state, controller);
    final theme = Theme.of(context);

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      color: AppColors.accentMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Please update DairyGo',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This version (${state.installed?.version ?? ''}) no '
                    'longer works with the Sacco system. Update to '
                    '${state.latest?.version ?? 'the new version'} to '
                    'continue. Your records are safe.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (status != null) ...[
                    if (status.downloading) ...[
                      LinearProgressIndicator(
                        value: status.progress,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                        color: AppColors.primary,
                        backgroundColor: AppColors.accentMint,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      status.downloading || status.isError
                          ? status.title
                          : (status.subtitle ?? ''),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: status.isError
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                    ),
                    if (status.downloading || status.isError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          status.subtitle ?? '',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: status.downloading
                          ? OutlinedButton(
                              onPressed: status.onAction,
                              child: Text(status.actionLabel!),
                            )
                          : FilledButton.icon(
                              onPressed: status.onAction,
                              icon: Icon(status.icon),
                              label: Text(
                                switch (status.actionLabel!) {
                                  'Update' => 'Update now',
                                  'Restart' => 'Restart to update',
                                  final label => label,
                                },
                              ),
                            ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    status == null
                        ? 'Download the new version in Chrome from:'
                        : 'If the update does not work, download it in '
                              'Chrome from:',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    ApiConstants.appPage.replaceFirst('https://', ''),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
