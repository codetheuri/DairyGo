import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// A saved API response and when it was saved.
class CachedResponse {
  final Object? data;
  final DateTime savedAt;

  const CachedResponse(this.data, this.savedAt);
}

/// The last response of every GET the app made, kept on the phone per user so
/// screens open instantly and still show data offline.
///
/// Entries live in memory and in files under the app's private support
/// folder (other apps cannot read it). The folder is per user and is deleted
/// on logout, so on a shared phone nobody sees another user's data.
class ResponseCache {
  final Future<Directory> Function() _locate;
  Future<Directory>? _located;

  // Looked up on first use, inside the callers' error handling.
  Future<Directory> get _directory => _located ??= _locate();
  final Map<String, CachedResponse> _memory = {};
  final _updates = StreamController<void>.broadcast();

  /// Responses saved before this moment are not shown instantly any more
  /// (see [markAllStale]), though they are still used when offline.
  DateTime _staleBefore = DateTime.fromMillisecondsSinceEpoch(0);

  /// How long a response is trusted without asking the server again.
  final Duration freshFor;

  /// At most this many responses are kept; the oldest are dropped.
  static const maxEntries = 400;

  ResponseCache(this._locate, {this.freshFor = const Duration(seconds: 20)});

  /// The cache for [userId] in the app's support folder.
  factory ResponseCache.forUser(int userId) => ResponseCache(
    () async => Directory('${(await _rootDirectory()).path}/$userId'),
  );

  static Future<Directory> _rootDirectory() async => Directory(
    '${(await getApplicationSupportDirectory()).path}/response_cache',
  );

  /// Deletes every user's saved responses (on logout or a rejected session).
  static Future<void> clearAll() async {
    try {
      final root = await _rootDirectory();
      if (await root.exists()) await root.delete(recursive: true);
    } catch (_) {
      // Best effort: a missing folder or plugin (tests) leaves nothing to clear.
    }
  }

  /// Fires when a background refresh brought data that differs from what
  /// was shown, so screens can reload from the cache.
  Stream<void> get updates => _updates.stream;

  // Keys are request paths and queries, so URL-safe base64 stays well under
  // file-name limits.
  static String _fileName(String key) =>
      '${base64Url.encode(utf8.encode(key)).replaceAll('=', '')}.json';

  Future<CachedResponse?> read(String key) async {
    final hit = _memory[key];
    if (hit != null) return hit;
    try {
      final file = File('${(await _directory).path}/${_fileName(key)}');
      if (!await file.exists()) return null;
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final entry = CachedResponse(
        json['data'],
        DateTime.fromMillisecondsSinceEpoch(json['savedAt'] as int),
      );
      _memory[key] = entry;
      return entry;
    } catch (_) {
      return null; // unreadable entry: behave as if there were none
    }
  }

  /// Saves [data] for [key]. Returns whether it differs from what was saved,
  /// i.e. whether screens showing the old copy are out of date.
  Future<bool> write(String key, Object? data) async {
    final previous = await read(key);
    final changed =
        previous == null || jsonEncode(previous.data) != jsonEncode(data);
    final entry = CachedResponse(data, DateTime.now());
    _memory[key] = entry;
    try {
      final dir = await _directory;
      await dir.create(recursive: true);
      await File('${dir.path}/${_fileName(key)}').writeAsString(
        jsonEncode({
          'savedAt': entry.savedAt.millisecondsSinceEpoch,
          'data': data,
        }),
      );
      await _trim(dir);
    } catch (_) {
      // Disk full or unavailable: the in-memory copy still serves this run.
    }
    return changed;
  }

  Future<void> _trim(Directory dir) async {
    final files = await dir
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();
    if (files.length <= maxEntries) return;
    files.sort(
      (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
    );
    for (final f in files.take(files.length - maxEntries)) {
      await f.delete();
    }
  }

  /// Whether [entry] may be shown straight away, before asking the server.
  bool canShowInstantly(CachedResponse entry) =>
      !entry.savedAt.isBefore(_staleBefore);

  /// Whether [entry] is recent enough that the server need not be asked.
  bool isFresh(CachedResponse entry) =>
      canShowInstantly(entry) &&
      DateTime.now().difference(entry.savedAt) < freshFor;

  /// Called after the user changes data (records milk, a sale, a price...).
  /// Saved copies may no longer match the server, so the next reads go to
  /// the network instead of showing them first.
  void markAllStale() => _staleBefore = DateTime.now();

  /// Tells listening screens that newer data has been saved.
  void notifyUpdated() {
    if (!_updates.isClosed) _updates.add(null);
  }

  void dispose() => _updates.close();
}
