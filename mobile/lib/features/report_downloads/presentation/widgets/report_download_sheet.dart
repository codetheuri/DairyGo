import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../customers/data/models/customer_models.dart';
import '../../../customers/presentation/widgets/customer_picker_sheet.dart';
import '../../../members/data/models/member_model.dart';
import '../../../members/presentation/widgets/farmer_picker_sheet.dart';
import '../../data/report_download_service.dart';
import '../../data/report_spec.dart';
import '../report_download_controller.dart';

/// Chooses what goes in a report (period, farmer or customer, format),
/// downloads it from the server, then opens or shares it.
class ReportDownloadSheet extends ConsumerStatefulWidget {
  final ReportSpec report;
  final MemberModel? farmer;
  final CustomerModel? customer;

  const ReportDownloadSheet({
    super.key,
    required this.report,
    this.farmer,
    this.customer,
  });

  static Future<void> show(
    BuildContext context,
    ReportSpec report, {
    MemberModel? farmer,
    CustomerModel? customer,
  }) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (_) =>
        ReportDownloadSheet(report: report, farmer: farmer, customer: customer),
  );

  @override
  ConsumerState<ReportDownloadSheet> createState() =>
      _ReportDownloadSheetState();
}

class _ReportDownloadSheetState extends ConsumerState<ReportDownloadSheet> {
  late final List<ReportPeriod> _presets = ReportPeriod.presets(DateTime.now());
  late ReportPeriod _period = _presets.first;
  ReportFormat _format = ReportFormat.pdf;
  String? _status;
  late MemberModel? _farmer = widget.farmer;
  late CustomerModel? _customer = widget.customer;

  bool _downloading = false;
  double? _progress;
  String? _error;
  File? _file;
  CancelToken? _cancel;

  ReportSpec get _report => widget.report;

  @override
  void dispose() {
    _cancel?.cancel();
    super.dispose();
  }

  Future<void> _pickCustom() async {
    final today = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      initialDateRange: DateTimeRange(start: _period.from, end: _period.to),
      helpText: 'Choose the period (at most a year)',
    );
    if (range == null) return;
    if (range.end.difference(range.start).inDays >= 366) {
      setState(() => _error = 'Choose a period of at most a year.');
      return;
    }
    setState(() {
      _period = ReportPeriod('Custom', range.start, range.end);
      _error = null;
    });
  }

  Future<void> _download() async {
    if (_report.needsFarmer && _farmer == null) {
      setState(() => _error = 'Choose a farmer.');
      return;
    }
    if (_report.needsCustomer && _customer == null) {
      setState(() => _error = 'Choose a customer.');
      return;
    }
    setState(() {
      _downloading = true;
      _progress = null;
      _error = null;
      _file = null;
    });
    _cancel = CancelToken();
    try {
      final file = await ref
          .read(reportDownloadServiceProvider)
          .download(
            _report,
            format: _format,
            period: _period,
            filters: ReportFilters(
              memberId: _farmer?.id,
              customerId: _customer?.id,
              status: _status,
            ),
            cancel: _cancel,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      ref.invalidate(savedReportsProvider);
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _file = file;
      });
    } on DioException {
      if (mounted) setState(() => _downloading = false); // cancelled
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _open() async {
    final problem = await ReportFiles.open(_file!);
    if (problem != null && mounted) setState(() => _error = problem);
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  );

  Widget _chip(String label, bool selected, VoidCallback? onTap) => ChoiceChip(
    label: Text(label),
    selected: selected,
    showCheckmark: false,
    selectedColor: AppColors.primary,
    labelStyle: TextStyle(
      color: selected ? Colors.white : AppColors.textPrimary,
      fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
    ),
    onSelected: onTap == null ? null : (_) => onTap(),
  );

  Widget _chosen({
    required IconData icon,
    required String empty,
    required String? value,
    required VoidCallback? onTap,
  }) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: value == null ? AppColors.cardBorder : AppColors.primary,
      ),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        value ?? empty,
        style: TextStyle(
          fontWeight: value == null ? FontWeight.normal : FontWeight.w600,
          color: value == null
              ? AppColors.textSecondary
              : AppColors.textPrimary,
        ),
      ),
      trailing: Text(
        value == null ? 'Choose' : 'Change',
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final busy = _downloading;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _report.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              _report.description,
              style: const TextStyle(color: AppColors.textSecondary),
            ),

            if (_report.needsFarmer) ...[
              _label('Farmer'),
              _chosen(
                icon: Icons.person_outline_rounded,
                empty: 'Choose a farmer',
                value: _farmer == null
                    ? null
                    : '${_farmer!.fullName} · ${_farmer!.membershipNumber}',
                onTap: busy
                    ? null
                    : () async {
                        final f = await FarmerPickerSheet.show(
                          context,
                          selectedMemberId: _farmer?.id,
                        );
                        if (f != null) setState(() => _farmer = f);
                      },
              ),
            ],
            if (_report.needsCustomer) ...[
              _label('Customer'),
              _chosen(
                icon: Icons.storefront_outlined,
                empty: 'Choose a customer',
                value: _customer?.name,
                onTap: busy
                    ? null
                    : () async {
                        final c = await CustomerPickerSheet.show(context);
                        if (c != null) setState(() => _customer = c);
                      },
              ),
            ],

            if (_report.asAt) ...[
              _label('Period'),
              const Text(
                'As at today',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ] else ...[
              _label('Period'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in _presets)
                    _chip(
                      p.label,
                      _period.label == p.label,
                      busy ? null : () => setState(() => _period = p),
                    ),
                  _chip(
                    'Custom…',
                    _period.label == 'Custom',
                    busy ? null : _pickCustom,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _period.dates,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],

            if (_report.statusFilter) ...[
              _label('Farmers'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (label, value) in const [
                    ('All', null),
                    ('Active', 'ACTIVE'),
                    ('Inactive', 'INACTIVE'),
                    ('Suspended', 'SUSPENDED'),
                  ])
                    _chip(
                      label,
                      _status == value,
                      busy ? null : () => setState(() => _status = value),
                    ),
                ],
              ),
            ],

            _label('Format'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in ReportFormat.values)
                  _chip(
                    f == ReportFormat.pdf
                        ? 'PDF (print, share)'
                        : 'Excel (accounts)',
                    _format == f,
                    busy ? null : () => setState(() => _format = f),
                  ),
              ],
            ),

            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 18),

            if (busy) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _progress == null
                          ? 'Making the report…'
                          : 'Downloading… ${(_progress! * 100).floor()}%',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _cancel?.cancel(),
                    child: const Text('Stop'),
                  ),
                ],
              ),
            ] else if (_file != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.successContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Downloaded: ${_file!.uri.pathSegments.last}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _open,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Open'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ReportFiles.share(_file!, _report.title),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _download,
                child: const Text('Download again'),
              ),
            ] else
              FilledButton.icon(
                onPressed: _download,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.download_rounded),
                label: Text('Download ${_format.label}'),
              ),
          ],
        ),
      ),
    );
  }
}
