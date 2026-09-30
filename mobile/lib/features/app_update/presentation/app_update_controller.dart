import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/app_release.dart';
import '../data/app_update_service.dart';

final appUpdateServiceProvider = Provider<AppUpdateService>(
  (ref) => AppUpdateService.create(),
);

/// The version installed on this phone.
final installedAppProvider = FutureProvider<InstalledApp>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return InstalledApp(
    version: info.version,
    build: int.tryParse(info.buildNumber) ?? 0,
  );
});

/// This phone's type, as release files are named (see [currentAbi]).
final deviceAbiProvider = Provider<String?>((ref) => currentAbi());

final appUpdateProvider = NotifierProvider<AppUpdateController, AppUpdateState>(
  AppUpdateController.new,
);

enum UpdateStep {
  /// Nothing in progress.
  idle,
  downloading,

  /// Downloaded; Android's installer was opened, or can be opened again.
  readyToInstall,

  /// The user must first allow DairyGo to install updates.
  needsPermission,
  failed,
}

class AppUpdateState {
  final InstalledApp? installed;
  final AppRelease? latest;

  /// This phone's type; null when no APK is published for it.
  final String? abi;
  final bool checking;
  final UpdateStep step;
  final int received;
  final int total;

  /// Why the last step failed, for the user.
  final String? error;

  /// The last check was asked for by the user and found nothing newer.
  final bool confirmedUpToDate;

  /// The user chose "Later" for this version (until the app restarts).
  final bool dismissed;

  const AppUpdateState({
    this.installed,
    this.latest,
    this.abi,
    this.checking = false,
    this.step = UpdateStep.idle,
    this.received = 0,
    this.total = 0,
    this.error,
    this.confirmedUpToDate = false,
    this.dismissed = false,
  });

  /// A newer version exists that this phone can install.
  bool get available {
    final i = installed, l = latest;
    return i != null &&
        l != null &&
        l.build > i.build &&
        l.files.containsKey(abi);
  }

  /// This version is no longer allowed: it must update before use.
  bool get required {
    final i = installed, l = latest;
    return i != null && l != null && i.build < l.minBuild && l.build > i.build;
  }

  double? get progress => total > 0 ? received / total : null;

  AppUpdateState copyWith({
    InstalledApp? installed,
    AppRelease? latest,
    bool clearLatest = false,
    String? abi,
    bool? checking,
    UpdateStep? step,
    int? received,
    int? total,
    String? error,
    bool clearError = false,
    bool? confirmedUpToDate,
    bool? dismissed,
  }) => AppUpdateState(
    installed: installed ?? this.installed,
    latest: clearLatest ? null : latest ?? this.latest,
    abi: abi ?? this.abi,
    checking: checking ?? this.checking,
    step: step ?? this.step,
    received: received ?? this.received,
    total: total ?? this.total,
    error: clearError ? null : error ?? this.error,
    confirmedUpToDate: confirmedUpToDate ?? this.confirmedUpToDate,
    dismissed: dismissed ?? this.dismissed,
  );
}

/// Checks for new versions (at start, on return to the app, and when asked),
/// downloads them and hands them to Android's installer.
class AppUpdateController extends Notifier<AppUpdateState> {
  /// Automatic checks are this far apart; the user can check any time.
  static const checkEvery = Duration(hours: 6);

  DateTime? _lastCheck;
  CancelToken? _cancel;
  String? _apkPath;

  AppUpdateService get _service => ref.read(appUpdateServiceProvider);

  @override
  AppUpdateState build() => AppUpdateState(abi: ref.read(deviceAbiProvider));

  /// Looks for a newer version. Automatic checks fail silently (the phone
  /// may be offline); a check the user asked for says what happened.
  Future<void> check({bool manual = false}) async {
    if (state.checking || state.step == UpdateStep.downloading) return;
    final last = _lastCheck;
    if (!manual &&
        last != null &&
        DateTime.now().difference(last) < checkEvery) {
      return;
    }
    state = state.copyWith(
      checking: true,
      clearError: true,
      confirmedUpToDate: false,
    );
    try {
      final installed =
          state.installed ?? await ref.read(installedAppProvider.future);
      final latest = await _service.fetchLatest();
      _lastCheck = DateTime.now();
      state = state.copyWith(
        installed: installed,
        latest: latest,
        clearLatest: latest == null,
        checking: false,
      );
      if (manual && !state.available) {
        state = state.copyWith(confirmedUpToDate: true);
      }
      unawaited(_service.removeOldDownloads(keepBuild: latest?.build));
    } catch (_) {
      state = state.copyWith(
        checking: false,
        error: manual
            ? 'Could not check for updates. Check your connection and try again.'
            : null,
      );
    }
  }

  /// Downloads the new version, then opens the installer.
  Future<void> update() async {
    final release = state.latest;
    final abi = state.abi;
    if (!state.available ||
        release == null ||
        abi == null ||
        state.step == UpdateStep.downloading) {
      return;
    }
    _cancel = CancelToken();
    state = state.copyWith(
      step: UpdateStep.downloading,
      received: 0,
      total: release.files[abi]!.size,
      clearError: true,
    );
    var shownPercent = -1;
    try {
      _apkPath = await _service.download(
        release,
        abi,
        cancel: _cancel,
        onProgress: (received, total) {
          // One update per percent, not per network chunk.
          final percent = total > 0 ? received * 100 ~/ total : 0;
          if (percent == shownPercent) return;
          shownPercent = percent;
          state = state.copyWith(received: received, total: total);
        },
      );
      await install();
    } on DioException catch (e) {
      state = CancelToken.isCancel(e)
          ? state.copyWith(step: UpdateStep.idle)
          : state.copyWith(
              step: UpdateStep.failed,
              error: UpdateException.stopped.message,
            );
    } on UpdateException catch (e) {
      state = state.copyWith(step: UpdateStep.failed, error: e.message);
    } catch (_) {
      state = state.copyWith(
        step: UpdateStep.failed,
        error: UpdateException.stopped.message,
      );
    }
  }

  /// Stops a download; what arrived is kept for next time.
  void cancel() => _cancel?.cancel();

  /// Opens Android's installer for the downloaded version, first asking for
  /// permission to install updates when needed.
  Future<void> install() async {
    final path = _apkPath;
    if (path == null) return;
    final installer = _service.installer;
    if (!await installer.canInstall()) {
      state = state.copyWith(step: UpdateStep.needsPermission);
      return;
    }
    final opened = await installer.install(path);
    state = opened
        ? state.copyWith(step: UpdateStep.readyToInstall)
        : state.copyWith(
            step: UpdateStep.failed,
            error:
                'Could not open the installer. Download the app from '
                'the DairyGo page instead.',
          );
  }

  /// Opens the switch that lets DairyGo install updates.
  Future<void> allowInstalls() => _service.installer.openSettings();

  /// Hides the "new version" strip until the app restarts. A required update
  /// cannot be put off.
  void later() => state = state.copyWith(dismissed: true);

  /// The app came back to the front: continue once installs are allowed,
  /// and look for a newer version now and then.
  Future<void> onResume() async {
    if (state.step == UpdateStep.needsPermission &&
        await _service.installer.canInstall()) {
      await install();
    }
    await check();
  }
}
