import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../core/db/app_database.dart';
import 'providers/content_provider.dart' show contentUserAgent;

/// Saves content media (books, audiobook chapters, sounds, videos) to the
/// app's private storage so it works offline.
///
/// - Streams to a temp file and renames on success, so a dropped connection
///   never leaves a half file that looks complete.
/// - Each file is recorded in `content_downloads`; those items are never
///   pruned from the catalogue.
/// - Books are saved automatically the first time they are opened (small);
///   audio and video are saved only when the user taps Download.
class DownloadService {
  DownloadService(this._db, {http.Client? client, Future<Directory> Function()? baseDir})
      : _client = client ?? http.Client(),
        _baseDir = baseDir ?? getApplicationSupportDirectory;

  static DownloadService? _instance;
  static DownloadService get instance => _instance ??= DownloadService(AppDatabase.instance);
  @visibleForTesting
  static set instance(DownloadService s) => _instance = s;

  final AppDatabase _db;
  final http.Client _client;
  final Future<Directory> Function() _baseDir;
  final _cancelled = <String>{};

  Future<Directory> _mediaDir() async {
    final d = Directory('${(await _baseDir()).path}/media');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  static String _fileName(String url) {
    final ext = RegExp(r'\.([a-zA-Z0-9]{2,5})(?:$|\?)').firstMatch(Uri.parse(url).path)?.group(1) ?? 'bin';
    return '${sha1.convert(url.codeUnits).toString().substring(0, 20)}.${ext.toLowerCase()}';
  }

  /// Local file for [url] if it was saved and still exists.
  Future<File?> localFile(String url) async {
    final row = await (_db.select(_db.contentDownloads)..where((t) => t.url.equals(url))).getSingleOrNull();
    if (row == null) return null;
    final f = File(row.localPath);
    if (await f.exists()) return f;
    await (_db.delete(_db.contentDownloads)..where((t) => t.url.equals(url))).go(); // file was cleared
    return null;
  }

  /// Downloads [url] for [contentId]. [onProgress] gets 0..1 (or null when
  /// the size is unknown). Returns the saved file.
  Future<File> download(String contentId, String url, {void Function(double? progress)? onProgress}) async {
    final existing = await localFile(url);
    if (existing != null) return existing;
    _cancelled.remove(url);
    final dir = await _mediaDir();
    final target = File('${dir.path}/${_fileName(url)}');
    final tmp = File('${target.path}.part');
    final req = http.Request('GET', Uri.parse(url))..headers['User-Agent'] = contentUserAgent;
    final resp = await _client.send(req).timeout(const Duration(seconds: 30));
    if (resp.statusCode != 200) {
      throw HttpException('HTTP ${resp.statusCode}', uri: Uri.parse(url));
    }
    final total = resp.contentLength;
    var received = 0;
    final sink = tmp.openWrite();
    try {
      await for (final chunk in resp.stream.timeout(const Duration(seconds: 60))) {
        if (_cancelled.contains(url)) throw const DownloadCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(total == null || total == 0 ? null : received / total);
      }
      await sink.flush();
      await sink.close();
    } catch (_) {
      await sink.close();
      if (await tmp.exists()) await tmp.delete();
      rethrow;
    }
    await tmp.rename(target.path);
    await _db.into(_db.contentDownloads).insertOnConflictUpdate(ContentDownloadsCompanion.insert(
          contentId: contentId,
          url: url,
          localPath: target.path,
          bytes: Value(received),
          savedAt: DateTime.now(),
        ));
    return target;
  }

  void cancel(String url) => _cancelled.add(url);

  /// Bytes of [url]: from disk if saved, otherwise downloaded and saved
  /// (used for books, which are small and should open offline next time).
  Future<Uint8List> bytesFor(String contentId, String url) async {
    final f = await download(contentId, url);
    return f.readAsBytes();
  }

  /// Removes every saved file of [contentId].
  Future<void> remove(String contentId) async {
    final rows = await (_db.select(_db.contentDownloads)..where((t) => t.contentId.equals(contentId))).get();
    for (final r in rows) {
      final f = File(r.localPath);
      if (await f.exists()) await f.delete();
    }
    await (_db.delete(_db.contentDownloads)..where((t) => t.contentId.equals(contentId))).go();
  }

  Future<void> clearAll() async {
    final dir = await _mediaDir();
    if (await dir.exists()) await dir.delete(recursive: true);
    await _db.delete(_db.contentDownloads).go();
  }

  /// Live list of saved files (for "Saved for offline" and storage use).
  Stream<List<ContentDownloadRow>> watchAll() => _db.select(_db.contentDownloads).watch();
}

class DownloadCancelled implements Exception {
  const DownloadCancelled();
  @override
  String toString() => 'Download cancelled';
}
