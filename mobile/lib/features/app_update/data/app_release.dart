/// One APK of a release.
class ReleaseFile {
  /// Download path on the API host, e.g. /app/download/arm64.
  final String url;
  final String sha256;
  final int size;

  const ReleaseFile({
    required this.url,
    required this.sha256,
    required this.size,
  });

  factory ReleaseFile.fromJson(Map<String, dynamic> json) => ReleaseFile(
    url: json['url'] as String,
    sha256: json['sha256'] as String,
    size: (json['size'] as num).toInt(),
  );
}

/// The latest published version of the app (GET /api/v1/app/version).
class AppRelease {
  final String version;

  /// Android version code; higher is newer.
  final int build;

  /// Apps older than this must update before they can be used.
  final int minBuild;
  final String notes;

  /// By phone type: 'arm64' (most phones) and 'armv7' (older phones).
  final Map<String, ReleaseFile> files;

  const AppRelease({
    required this.version,
    required this.build,
    required this.minBuild,
    this.notes = '',
    required this.files,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) => AppRelease(
    version: json['version'] as String,
    build: (json['build'] as num).toInt(),
    minBuild: (json['min_build'] as num?)?.toInt() ?? 0,
    notes: json['notes'] as String? ?? '',
    files: {
      for (final e in (json['files'] as Map<String, dynamic>? ?? {}).entries)
        e.key: ReleaseFile.fromJson(e.value as Map<String, dynamic>),
    },
  );
}

/// The version installed on this phone.
class InstalledApp {
  final String version;
  final int build;

  const InstalledApp({required this.version, required this.build});
}

/// The build number from pubspec.yaml, given Android's versionCode.
///
/// An APK built with --split-per-abi does not carry the build number as its
/// versionCode: Flutter adds 1000 for armv7 and 2000 for arm64 (build 11 is
/// installed as 1011 or 2011), so that a phone always prefers its own type.
/// Releases are published by build number, so the two must be compared in
/// the same scale. Build numbers therefore stay below 1000.
int releaseBuild(int versionCode) => versionCode % 1000;
