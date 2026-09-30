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
    build: releaseBuild(int.tryParse(info.buildNumber) ?? 0),
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

  /// Downloaded; the user taps Restart to install it.
  readyToInstall,

  /// Handed to Android, which closes the app when the update is in place.
  installing,

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

  /// Downloading by itself on Wi-Fi: nothing is shown until it is ready.
  final bool quiet;
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
    this.quiet = false,
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
    bool? quiet,
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
    quiet: quiet ?? this.quiet,
    received: received ?? this.received,
    total: total ?? this.total,
    error: clearError ? null : error ?? this.error,
    confirmedUpToDate: confirmedUpToDate ?? this.confirmedUpToDate,
    dismissed: dismissed ?? this.dismissed,
  );
}

/// Checks for new versions (at start, on return to the app, and when asked)
/// and installs them.
///
/// On Wi-Fi a new version downloads by itself; once it is ready the user
/// taps Restart and Android swaps the app for the new version. On mobile
/// data the user starts the download (Update), and it installs when done.
class AppUpdateController extends Notifier<AppUpdateState> {
  /// Automatic checks are this far apart; the user can check any time.
  static const checkEvery = Duration(hours: 6);

  DateTime? _lastCheck;
  CancelToken? _cancel;
  String? _apkPath;

  AppUpdateService get _service => ref.read(appUpdateServiceProvider);

  @override
  AppUpdateState build() {
    final results = _service.installer.results.listen(_onInstallResult);
    ref.onDispose(results.cancel);
    return AppUpdateState(abi: ref.read(deviceAbiProvider));
  }

  /// Looks for a newer version. Automatic checks fail silently (the phone
  /// may be offline); a check the user asked for says what happened.
  Future<void> check({bool manual = false}) async {
    // Not while an update is under way (a failed one can be checked again).
    final busy =
        state.step != UpdateStep.idle && state.step != UpdateStep.failed;
    if (state.checking || busy) return;
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
      final found = state.copyWith(
        installed: installed,
        latest: latest,
        clearLatest: latest == null,
        checking: false,
      );
      unawaited(_service.removeOldDownloads(keepBuild: latest?.build));

      // Decide how to offer it before showing anything, so the offer does
      // not flash up and change a moment later.
      final abi = found.abi;
      if (found.available && latest != null && abi != null) {
        _apkPath = await _service.downloaded(latest, abi);
        if (_apkPath != null) {
          state = found.copyWith(step: UpdateStep.readyToInstall);
          return;
        }
        if (await _service.onWifi()) {
          state = found;
          unawaited(_download(quiet: true));
          return;
        }
      }
      state = found.copyWith(confirmedUpToDate: manual && !found.available);
    } catch (_) {
      state = state.copyWith(
        checking: false,
        error: manual
            ? 'Could not check for updates. Check your connection and try again.'
            : null,
      );
    }
  }

  /// The user asked for the new version: downloads it, then installs it.
  Future<void> update() async {
    if (await _download(quiet: false) != null) await install();
  }

  /// Downloads the new version and returns its file, or null when it did
  /// not finish. A [quiet] download shows nothing until it is ready, and
  /// failing only leaves the usual "new version" offer.
  Future<String?> _download({required bool quiet}) async {
    final release = state.latest;
    final abi = state.abi;
    if (!state.available ||
        release == null ||
        abi == null ||
        state.step == UpdateStep.downloading) {
      return null;
    }
    _cancel = CancelToken();
    state = state.copyWith(
      step: UpdateStep.downloading,
      quiet: quiet,
      dismissed: quiet ? null : false,
      received: 0,
      total: release.files[abi]!.size,
      clearError: true,
    );
    var shownPercent = -1;
    String error;
    try {
      final path = await _service.download(
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
      _apkPath = path;
      state = state.copyWith(
        step: UpdateStep.readyToInstall,
        quiet: false,
        // Ready to use: offered again even if the user put the offer off.
        dismissed: false,
      );
      return path;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = state.copyWith(step: UpdateStep.idle, quiet: false);
        return null;
      }
      error = UpdateException.stopped.message;
    } on UpdateException catch (e) {
      error = e.message;
    } catch (_) {
      error = UpdateException.stopped.message;
    }
    state = quiet
        ? state.copyWith(step: UpdateStep.idle, quiet: false)
        : state.copyWith(step: UpdateStep.failed, error: error);
    return null;
  }

  /// Stops a download; what arrived is kept for next time.
  void cancel() => _cancel?.cancel();

  /// Installs the downloaded version ("Restart"), first asking for
  /// permission to install updates when needed. Android closes the app once
  /// the new version is in place, and usually opens it again.
  Future<void> install() async {
    final path = _apkPath;
    if (path == null) return;
    final installer = _service.installer;
    if (!await installer.canInstall()) {
      state = state.copyWith(step: UpdateStep.needsPermission);
      return;
    }
    state = state.copyWith(step: UpdateStep.installing, clearError: true);
    if (!await installer.install(path)) {
      state = state.copyWith(
        step: UpdateStep.failed,
        error:
            'Could not start the update. Download the app from the '
            'DairyGo page instead.',
      );
    }
  }

  void _onInstallResult(InstallResult result) {
    if (state.step != UpdateStep.installing) return;
    switch (result.outcome) {
      case InstallOutcome.confirming:
        break;
      case InstallOutcome.cancelled:
        state = state.copyWith(step: UpdateStep.readyToInstall);
      case InstallOutcome.failed:
        final why = result.message;
        state = state.copyWith(
          step: UpdateStep.failed,
          error:
              'Android did not install the update'
              '${why == null || why.isEmpty ? '' : ' ($why)'}. Tap Try again.',
        );
    }
  }

  /// Opens the switch that lets DairyGo install updates.
  Future<void> allowInstalls() => _service.installer.openSettings();

  /// Hides the update strip until the app restarts. A required update
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
