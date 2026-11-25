import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/db/app_database.dart';
import 'content_repository.dart';
import 'providers/archive_audiobook_provider.dart';
import 'providers/commons_video_provider.dart';
import 'providers/content_provider.dart';
import 'providers/gutendex_provider.dart';
import 'providers/wger_provider.dart';
import 'providers/wikimedia_audio_provider.dart';
import 'providers/youtube_channel_provider.dart';

class ProviderSyncResult {
  final String provider;
  final bool skipped;
  final int newItems;
  final int fetched;
  final String? error;
  const ProviderSyncResult(this.provider,
      {this.skipped = false, this.newItems = 0, this.fetched = 0, this.error});

  @override
  String toString() => skipped
      ? '$provider: fresh'
      : error != null
          ? '$provider: error $error'
          : '$provider: $fetched items, $newItems new';
}

/// Checks every provider each time the app opens or returns to the
/// foreground (and from the Android background job); a provider is
/// re-downloaded when its last successful refresh is older than its
/// interval (books 1 h, audiobooks/sounds 6 h, videos 12 h, exercises 24 h).
/// "Check now" forces a refresh.
///
/// - Offline or provider down: the cached catalogue keeps working; the error
///   is recorded and retried after a short back-off.
/// - Providers are isolated: one failing never blocks the others.
/// - An empty response never wipes the cache.
class ContentSyncService {
  ContentSyncService({
    required ContentRepository repository,
    List<ContentProvider>? providers,
    http.Client? client,
    DateTime Function()? clock,
  })  : _repo = repository,
        providers = providers ?? defaultProviders(),
        _client = client ?? http.Client(),
        _clock = clock ?? DateTime.now;

  static ContentSyncService? _instance;
  static ContentSyncService get instance =>
      _instance ??= ContentSyncService(repository: ContentRepository(AppDatabase.instance));

  static List<ContentProvider> defaultProviders() => [
        GutendexProvider(),
        ArchiveAudiobookProvider(),
        WikimediaAudioProvider(),
        WgerProvider(),
        CommonsVideoProvider(),
        YoutubeChannelProvider(),
      ];

  static const failureBackoff = Duration(minutes: 15);

  final ContentRepository _repo;
  final List<ContentProvider> providers;
  final http.Client _client;
  final DateTime Function() _clock;

  Future<List<ProviderSyncResult>>? _running;

  /// Safe to call often; concurrent calls share one run.
  Future<List<ProviderSyncResult>> syncIfStale({bool force = false}) {
    return _running ??= _syncAll(force).whenComplete(() => _running = null);
  }

  Future<List<ProviderSyncResult>> _syncAll(bool force) async {
    // Providers run in parallel and are isolated from each other.
    final results = await Future.wait(providers.map((p) => _syncOne(p, force)));
    try {
      await _repo.prune(now: _clock());
    } catch (_) {}
    debugPrint('[ContentSync] ${results.join('; ')}');
    return results;
  }

  Future<ProviderSyncResult> _syncOne(ContentProvider p, bool force) async {
    final now = _clock();
    final state = await _repo.syncState(p.id);
    if (!force && state != null) {
      final lastOk = state.lastSuccessAt;
      if (lastOk != null && now.difference(lastOk) < p.refreshEvery) {
        return ProviderSyncResult(p.id, skipped: true);
      }
      final lastTry = state.lastAttemptAt;
      final failedRecently = state.lastError != null &&
          lastTry != null &&
          now.difference(lastTry) < failureBackoff;
      if (failedRecently) return ProviderSyncResult(p.id, skipped: true);
    }

    await _repo.recordAttempt(p.id, now);
    try {
      final items = await p.fetch(_client, now: now);
      if (items.isEmpty) throw StateError('provider returned no items');
      final added = await _repo.upsert(p.id, items, now: now, firstSync: state?.lastSuccessAt == null);
      await _repo.recordSuccess(p.id, now);
      return ProviderSyncResult(p.id, fetched: items.length, newItems: added);
    } catch (e) {
      final msg = e.toString();
      await _repo.recordFailure(p.id, msg.length > 300 ? msg.substring(0, 300) : msg);
      return ProviderSyncResult(p.id, error: msg);
    }
  }
}
