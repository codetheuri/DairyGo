import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/api_constants.dart';
import 'app_release.dart';

/// Why an update could not be downloaded, in words for the user.
class UpdateException implements Exception {
  final String message;
  const UpdateException(this.message);

  static const stopped = UpdateException(
    'The download stopped. Tap Update to continue where it stopped.',
  );

  @override
  String toString() => message;
}

/// The phone type this app was built for, as release files are named, or
/// null on phones no APK is published for (for example emulators).
String? currentAbi() => switch (Abi.current()) {
  Abi.androidArm64 => 'arm64',
  Abi.androidArm => 'armv7',
  _ => null,
};

/// Android's installer, reached through MainActivity.kt.
class UpdateInstaller {
  static const _channel = MethodChannel('dairygo/app_update');

  /// The app's private folder for downloaded updates.
  Future<String> updatesDir() async =>
      (await _channel.invokeMethod<String>('updatesDir'))!;

  /// Whether the user allowed DairyGo to install updates.
  Future<bool> canInstall() async =>
      await _channel.invokeMethod<bool>('canInstall') ?? false;

  /// Opens the "Install unknown apps" switch for DairyGo.
  Future<bool> openSettings() async =>
      await _channel.invokeMethod<bool>('openInstallSettings') ?? false;

  /// Opens Android's installer for [path]; the user confirms there.
  Future<bool> install(String path) async =>
      await _channel.invokeMethod<bool>('install', {'path': path}) ?? false;
}

/// Finds and downloads new versions of the app.
///
/// Downloads continue where they stopped (a 21 MB file takes about half an
/// hour at 100 kbps, and connections drop), and every file is checked
/// against the release's SHA-256 before it is installed. Android then checks
/// it is signed with the same key as the installed app.
class AppUpdateService {
  final Dio _dio;
  final UpdateInstaller installer;

  AppUpdateService(this._dio, this.installer);

  /// A client of its own: no sign-in (an outdated app may not be able to
  /// sign in), no saved copies, and a timeout between received chunks
  /// rather than for the whole file.
  factory AppUpdateService.create() => AppUpdateService(
    Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectionTimeout,
        receiveTimeout: const Duration(seconds: 60),
      ),
    ),
    UpdateInstaller(),
  );

  /// The latest release, or null when none is published.
  Future<AppRelease?> fetchLatest() async {
    try {
      // scheme 2: builds are compared as numbered in pubspec.yaml (see
      // [releaseBuild]); the server answers older apps in their own scale.
      final res = await _dio.get<Map<String, dynamic>>(
        ApiConstants.appVersion,
        queryParameters: const {'scheme': 2},
      );
      return AppRelease.fromJson(res.data!['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  static String _fileName(AppRelease r, String abi) =>
      'DairyGo-${r.build}-$abi.apk';

  /// Downloads [release]'s APK for [abi] and returns its path, reporting
  /// bytes received so far out of the total.
  Future<String> download(
    AppRelease release,
    String abi, {
    CancelToken? cancel,
    void Function(int received, int total)? onProgress,
  }) async {
    final file = release.files[abi];
    if (file == null) {
      throw const UpdateException(
        'This update is not available for this phone.',
      );
    }
    final dir = await installer.updatesDir();
    final done = File('$dir/${_fileName(release, abi)}');
    final part = File('${done.path}.part');

    // Downloaded before (the installer was closed, or the app restarted).
    if (await done.exists() && await _matches(done, file)) {
      onProgress?.call(file.size, file.size);
      return done.path;
    }

    var start = await part.exists() ? await part.length() : 0;
    if (start > file.size) {
      await part.delete();
      start = 0;
    }
    if (start < file.size) {
      final res = await _dio.get<ResponseBody>(
        file.url,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          // Continue from the saved part, unless the file on the server
          // changed (then the whole file comes back with 200).
          headers: start > 0
              ? {'Range': 'bytes=$start-', 'If-Range': '"${file.sha256}"'}
              : null,
        ),
      );
      if (res.statusCode != 206) start = 0;
      final sink = part.openWrite(
        mode: start > 0 ? FileMode.append : FileMode.write,
      );
      var received = start;
      onProgress?.call(received, file.size);
      try {
        await for (final chunk in res.data!.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, file.size);
        }
      } finally {
        await sink.close();
      }
    }

    // The connection closed early: keep what arrived for next time.
    if (await part.length() < file.size) throw UpdateException.stopped;
    if (!await _matches(part, file)) {
      await part.delete();
      throw const UpdateException(
        'The download was damaged. Tap Update to download it again.',
      );
    }
    await part.rename(done.path);
    return done.path;
  }

  Future<bool> _matches(File f, ReleaseFile expected) async {
    if (await f.length() != expected.size) return false;
    final digest = await sha256.bind(f.openRead()).first;
    return digest.toString() == expected.sha256;
  }

  /// Deletes downloads of other versions (installed or replaced).
  Future<void> removeOldDownloads({int? keepBuild}) async {
    try {
      final dir = Directory(await installer.updatesDir());
      await for (final f in dir.list()) {
        final keep =
            keepBuild != null && f.path.contains('/DairyGo-$keepBuild-');
        if (f is File && !keep) await f.delete();
      }
    } catch (_) {
      // Best effort: a leftover file is only disk space.
    }
  }
}
