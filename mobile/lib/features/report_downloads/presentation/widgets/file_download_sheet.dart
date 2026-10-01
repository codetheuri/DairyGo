import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../report_download_controller.dart';

/// Downloads one file the server makes (a payslip, a pay run register, a
/// payment list) as soon as it opens, then offers Open, Share and Save to
/// phone, like the report downloads.
class FileDownloadSheet extends ConsumerStatefulWidget {
  final String title;
  final String path;
  final Map<String, dynamic> query;
  final String fallbackName;

  const FileDownloadSheet({
    super.key,
    required this.title,
    required this.path,
    this.query = const {},
    required this.fallbackName,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String path,
    Map<String, dynamic> query = const {},
    required String fallbackName,
  }) => showModalBottomSheet(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => FileDownloadSheet(
      title: title,
      path: path,
      query: query,
      fallbackName: fallbackName,
    ),
  );

  @override
  ConsumerState<FileDownloadSheet> createState() => _FileDownloadSheetState();
}

class _FileDownloadSheetState extends ConsumerState<FileDownloadSheet> {
  final _cancel = CancelToken();
  double? _progress;
  File? _file;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _download();
  }

  @override
  void dispose() {
    _cancel.cancel();
    super.dispose();
  }

  Future<void> _download() async {
    setState(() {
      _file = null;
      _error = null;
      _progress = null;
    });
    try {
      final file = await ref
          .read(reportDownloadServiceProvider)
          .downloadPath(
            widget.path,
            query: widget.query,
            fallbackName: widget.fallbackName,
            cancel: _cancel,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      ref.invalidate(savedReportsProvider);
      if (mounted) setState(() => _file = file);
    } on DioException {
      // Closed before it finished.
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _open() async {
    final problem = await ReportFiles.open(_file!);
    if (problem != null && mounted) setState(() => _error = problem);
  }

  Future<void> _save() async {
    final message = await ReportFiles.saveToPhone(_file!);
    if (message == null || !mounted) return;
    final ok = message.startsWith('Saved');
    setState(() {
      _notice = ok ? message : null;
      _error = ok ? null : message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = _file;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: 12),
            if (file == null)
              FilledButton.icon(
                onPressed: _download,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
          ] else if (file == null) ...[
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(
              _progress == null
                  ? 'Making the file…'
                  : 'Downloading… ${(_progress! * 100).floor()}%',
            ),
          ],
          if (file != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    file.uri.pathSegments.last,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
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
                    onPressed: () => ReportFiles.share(file, widget.title),
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Save to phone'),
            ),
            if (_notice != null) ...[
              const SizedBox(height: 8),
              Text(
                _notice!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.success),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
