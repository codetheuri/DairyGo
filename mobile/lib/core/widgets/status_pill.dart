import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

enum StatusType { success, warning, error, info }

class StatusPill extends StatelessWidget {
  final String status;
  final StatusType type;

  const StatusPill({
    super.key,
    required this.status,
    this.type = StatusType.info,
  });

  factory StatusPill.fromStatusString(String status) {
    final s = status.toUpperCase();
    if (s == 'VERIFIED' || s == 'PAID' || s == 'SUCCESS') {
      return StatusPill(status: status, type: StatusType.success);
    } else if (s == 'SUBMITTED' || s == 'PENDING') {
      return StatusPill(status: status, type: StatusType.warning);
    } else if (s == 'REJECTED' || s == 'CANCELLED' || s == 'FAILED') {
      return StatusPill(status: status, type: StatusType.error);
    }
    return StatusPill(status: status, type: StatusType.info);
  }

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case StatusType.success:
        bg = AppColors.successContainer;
        fg = AppColors.success;
        break;
      case StatusType.warning:
        bg = AppColors.warningContainer;
        fg = AppColors.warning;
        break;
      case StatusType.error:
        bg = AppColors.errorContainer;
        fg = AppColors.error;
        break;
      case StatusType.info:
        bg = AppColors.infoContainer;
        fg = AppColors.info;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
