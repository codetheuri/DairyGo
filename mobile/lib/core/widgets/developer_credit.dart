import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../constants/developer.dart';

/// A quiet "Developed by" line for the foot of the splash and sign-in screens.
class DeveloperCredit extends StatelessWidget {
  const DeveloperCredit({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Text(
      'Developed by ${Developer.name} · ${Developer.phone}',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
  );
}
