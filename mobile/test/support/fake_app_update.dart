// Stand-ins for the in-app updater, so tests never reach the real server or
// Android's installer.

import 'package:dairy_sacco_mobile/features/app_update/data/app_release.dart';
import 'package:dairy_sacco_mobile/features/app_update/data/app_update_service.dart';
import 'package:dairy_sacco_mobile/features/app_update/presentation/app_update_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const installedForTests = InstalledApp(version: '1.4.0', build: 10);

AppRelease releaseForTests({int build = 11, int minBuild = 10}) => AppRelease(
  version: '1.4.$build',
  build: build,
  minBuild: minBuild,
  notes: 'Faster screens',
  files: const {
    'arm64': ReleaseFile(
      url: '/app/download/arm64',
      sha256: 'abc',
      size: 20 * 1024 * 1024,
    ),
  },
);

class FakeInstaller extends UpdateInstaller {
  bool allowed;
  final List<String> installed = [];
  int settingsOpened = 0;
  final String dir;

  FakeInstaller({this.allowed = true, this.dir = '/nowhere'});

  @override
  Future<String> updatesDir() async => dir;
  @override
  Future<bool> canInstall() async => allowed;
  @override
  Future<bool> openSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<bool> install(String path) async {
    installed.add(path);
    return true;
  }
}

class FakeAppUpdateService extends AppUpdateService {
  AppRelease? latest;
  int checks = 0;
  Object? checkError;

  /// Thrown by [download] instead of finishing, when set.
  Object? downloadError;

  FakeAppUpdateService({this.latest, FakeInstaller? installer})
    : super(Dio(), installer ?? FakeInstaller());

  FakeInstaller get fakeInstaller => installer as FakeInstaller;

  @override
  Future<AppRelease?> fetchLatest() async {
    checks++;
    if (checkError != null) throw checkError!;
    return latest;
  }

  @override
  Future<String> download(
    AppRelease release,
    String abi, {
    CancelToken? cancel,
    void Function(int received, int total)? onProgress,
  }) async {
    final size = release.files[abi]!.size;
    onProgress?.call(size ~/ 2, size);
    if (downloadError != null) throw downloadError!;
    onProgress?.call(size, size);
    return '/updates/DairyGo-${release.build}-$abi.apk';
  }

  @override
  Future<void> removeOldDownloads({int? keepBuild}) async {}
}

/// Overrides that put the updater on [service] (nothing published by
/// default), with this app at [installedForTests] on an arm64 phone.
List<Override> fakeUpdateOverrides([FakeAppUpdateService? service]) => [
  appUpdateServiceProvider.overrideWithValue(service ?? FakeAppUpdateService()),
  installedAppProvider.overrideWith((ref) async => installedForTests),
  deviceAbiProvider.overrideWithValue('arm64'),
];
