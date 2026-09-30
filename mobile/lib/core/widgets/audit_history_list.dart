import 'dart:convert';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../models/audit_log_model.dart';

/// Lists audit entries as "Edited by X", the time, the changed fields and the reason.
///
/// [fieldLabels] maps JSON keys in the snapshots to readable labels; only those
/// fields are compared. [createdSummary] describes a CREATE entry from its new values.
class AuditHistoryList extends StatelessWidget {
  final List<AuditLogModel> entries;
  final Map<String, String> fieldLabels;
  final List<String> Function(Map<String, dynamic> newValues)? createdSummary;

  const AuditHistoryList({
    super.key,
    required this.entries,
    required this.fieldLabels,
    this.createdSummary,
  });

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Text(
        'No history recorded.',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 16, color: AppColors.cardBorder),
      itemBuilder: (_, i) => _AuditTile(
        entry: entries[i],
        fieldLabels: fieldLabels,
        createdSummary: createdSummary,
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final AuditLogModel entry;
  final Map<String, String> fieldLabels;
  final List<String> Function(Map<String, dynamic> newValues)? createdSummary;

  const _AuditTile({
    required this.entry,
    required this.fieldLabels,
    this.createdSummary,
  });

  String get _title {
    switch (entry.action) {
      case 'CREATE':
        return 'Recorded';
      case 'UPDATE':
        return 'Edited';
      case 'STATUS':
        return 'Status changed';
      case 'VOID':
        return 'Voided';
      default:
        return entry.action;
    }
  }

  IconData get _icon {
    switch (entry.action) {
      case 'CREATE':
        return Icons.add_circle_outline_rounded;
      case 'STATUS':
        return Icons.verified_outlined;
      case 'VOID':
        return Icons.block_rounded;
      default:
        return Icons.edit_outlined;
    }
  }

  static String _formatTime(String? value) {
    final parsed = DateTime.tryParse(value ?? '')?.toLocal();
    if (parsed == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${parsed.year}-${two(parsed.month)}-${two(parsed.day)} ${two(parsed.hour)}:${two(parsed.minute)}';
  }

  static Map<String, dynamic> _decode(String? json) {
    if (json == null || json.isEmpty) return const {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return const {};
    }
  }

  /// "Field: old → new" lines for the fields that changed.
  List<String> _changes() {
    final before = _decode(entry.oldValues);
    final after = _decode(entry.newValues);
    if (entry.action == 'CREATE') {
      return createdSummary?.call(after) ?? const [];
    }
    final lines = <String>[];
    fieldLabels.forEach((key, label) {
      final oldValue = before[key];
      final newValue = after[key];
      if (oldValue != newValue) {
        lines.add('$label: ${oldValue ?? '—'} → ${newValue ?? '—'}');
      }
    });
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          _icon,
          size: 18,
          color: entry.action == 'VOID' ? AppColors.error : AppColors.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // No person: DairyGo did it (for example marking a farmer
                // inactive after a period without milk).
                '$_title by ${entry.actorName ?? 'DairyGo (automatic)'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                _formatTime(entry.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
              for (final line in _changes())
                Text(
                  line,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (entry.reason != null && entry.reason!.isNotEmpty)
                Text(
                  'Reason: ${entry.reason}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
