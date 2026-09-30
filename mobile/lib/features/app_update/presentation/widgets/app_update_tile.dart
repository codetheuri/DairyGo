import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../app_update_controller.dart';
import 'update_gate.dart';

/// The app's version on the More page, with checking and updating.
class AppUpdateTile extends ConsumerWidget {
  const AppUpdateTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appUpdateProvider);
    final controller = ref.read(appUpdateProvider.notifier);
    final installed =
        state.installed ?? ref.watch(installedAppProvider).valueOrNull;
    final status = UpdateStatus.of(state, controller);

    final String subtitle;
    if (status != null) {
      subtitle = status.downloading || status.isError
          ? '${status.title}\n${status.subtitle ?? ''}'
          : status.title;
    } else if (state.checking) {
      subtitle = 'Checking for updates…';
    } else if (state.error != null) {
      subtitle = state.error!;
    } else if (state.confirmedUpToDate) {
      subtitle = 'Up to date';
    } else {
      subtitle = 'Tap Check to look for a new version';
    }

    return ListTile(
      leading: Icon(
        status != null ? Icons.system_update_rounded : Icons.verified_outlined,
        color: status?.isError ?? false ? AppColors.error : AppColors.primary,
      ),
      title: Text('App version ${installed?.version ?? ''}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if (status?.downloading ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(value: status!.progress),
            ),
        ],
      ),
      isThreeLine: status?.downloading ?? false,
      trailing: status != null
          ? FilledButton(
              onPressed: status.onAction,
              child: Text(status.actionLabel!),
            )
          : TextButton(
              onPressed: state.checking
                  ? null
                  : () => controller.check(manual: true),
              child: const Text('Check'),
            ),
    );
  }
}
