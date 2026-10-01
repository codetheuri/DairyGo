import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/developer.dart';
import '../../../app_update/presentation/app_update_controller.dart';

/// "About DairyGo" on the More page: who made the app and how to reach them.
class AboutTile extends StatelessWidget {
  const AboutTile({super.key});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
    title: const Text('About DairyGo'),
    subtitle: const Text('Developed by ${Developer.name}'),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => const AboutSheet(),
    ),
  );
}

class AboutSheet extends ConsumerWidget {
  const AboutSheet({super.key});

  /// Opens the phone's dialer or mail app. When none can, the detail is
  /// copied so it can be pasted elsewhere.
  Future<void> _open(BuildContext context, Uri uri, String copy) async {
    final opened = await launchUrl(uri).catchError((_) => false);
    if (opened || !context.mounted) return;
    await Clipboard.setData(ClipboardData(text: copy));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Copied $copy')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(installedAppProvider).valueOrNull?.version;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Image.asset('assets/images/logo.png', height: 56)),
          const SizedBox(height: 10),
          Text(
            version == null ? 'DairyGo' : 'DairyGo $version',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text(
            'Milk collection, sales and payouts for dairy Saccos',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Developer',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline_rounded),
            title: const Text(Developer.name),
            subtitle: const Text(Developer.role),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.call_outlined, color: AppColors.primary),
            title: const Text(Developer.phone),
            subtitle: const Text('Call for help or support'),
            onTap: () => _open(
              context,
              Uri(scheme: 'tel', path: Developer.dialPhone),
              Developer.phone,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.mail_outline_rounded,
              color: AppColors.primary,
            ),
            title: const Text(Developer.email),
            subtitle: const Text('Email'),
            onTap: () => _open(
              context,
              Uri(
                scheme: 'mailto',
                path: Developer.email,
                query: 'subject=DairyGo${version == null ? '' : ' $version'}',
              ),
              Developer.email,
            ),
          ),
          const Divider(),
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'DairyGo',
              applicationVersion: version,
            ),
            child: const Text('Open-source licences'),
          ),
        ],
      ),
    );
  }
}
