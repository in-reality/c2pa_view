import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fetches, caches, and serves C2PA trust list PEM bundles.
///
/// On native platforms (when [cacheDirectory] is provided), the lists are
/// persisted locally and refreshed at [refreshInterval]. On web (or when
/// no cache directory is set) the lists are held in memory only.
class TrustListService {
  /// Creates a [TrustListService].
  ///
  /// [cacheDirectory] should point to a writable directory (e.g. from
  /// `path_provider`'s `getApplicationDocumentsDirectory()`). Pass null
  /// on web or when no local caching is needed.
  TrustListService({
    this.cacheDirectory,
    this.refreshInterval = const Duration(days: 7),
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  static const c2paTrustListUrl =
      'https://raw.githubusercontent.com/c2pa-org/conformance-public/main/trust-list/C2PA-TRUST-LIST.pem';
  static const tsaTrustListUrl =
      'https://raw.githubusercontent.com/c2pa-org/conformance-public/main/trust-list/C2PA-TSA-TRUST-LIST.pem';

  // Legacy combined cache cannot recover purpose; refetch the two origins.
  static const _cacheFileName = 'c2pa_manifest_trust_anchors.pem';
  static const _tsaCacheFileName = 'c2pa_tsa_trust_anchors.pem';
  static const _cacheTimestampFileName = 'c2pa_trust_anchors_ts.txt';

  /// Local directory for caching trust lists, or null to disable caching.
  final String? cacheDirectory;

  final Duration refreshInterval;
  final http.Client _httpClient;

  String? _cachedPem;
  String? _cachedTimestampPem;

  /// Whether a trust list is currently available (either from cache or fetch).
  bool get isAvailable => _cachedPem != null && _cachedTimestampPem != null;

  /// Manifest-signing CAs from the C2PA trust list, or null if unavailable.
  String? get trustAnchorsPem => _cachedPem;

  /// TSA CAs from the separate C2PA TSA trust list, or null if unavailable.
  String? get timestampTrustAnchorsPem => _cachedTimestampPem;

  /// Attempt to load trust lists: first from local cache, then from network.
  ///
  /// Returns `true` if a trust list is now available.
  Future<bool> initialize() async {
    if (cacheDirectory != null) {
      final cached = _readLocalCache();
      if (cached != null) {
        _cachedPem = cached.$1;
        _cachedTimestampPem = cached.$2;
        _maybeRefreshInBackground();
        return true;
      }
    }

    return _fetchAndCache();
  }

  /// Force a fresh fetch from the network.
  Future<bool> refresh() => _fetchAndCache();

  Future<bool> _fetchAndCache() async {
    try {
      final c2paPem = await _fetchPem(c2paTrustListUrl);
      final tsaPem = await _fetchPem(tsaTrustListUrl);
      _cachedPem = c2paPem;
      _cachedTimestampPem = tsaPem;

      if (cacheDirectory != null) {
        _writeLocalCache(c2paPem, tsaPem);
      }
      return true;
    } catch (e) {
      debugPrint('[TrustListService] Fetch failed: $e');
      return false;
    }
  }

  Future<String> _fetchPem(String url) async {
    final response = await _httpClient.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode} fetching $url');
    }
    return response.body;
  }

  (String, String)? _readLocalCache() {
    try {
      final file = File('$cacheDirectory/$_cacheFileName');
      final tsaFile = File('$cacheDirectory/$_tsaCacheFileName');
      if (!file.existsSync() || !tsaFile.existsSync()) {
        return null;
      }
      return (file.readAsStringSync(), tsaFile.readAsStringSync());
    } catch (e) {
      debugPrint('[TrustListService] Cache read failed: $e');
      return null;
    }
  }

  void _writeLocalCache(final String pem, final String timestampPem) {
    try {
      final file = File('$cacheDirectory/$_cacheFileName');
      file.writeAsStringSync(pem);
      File(
        '$cacheDirectory/$_tsaCacheFileName',
      ).writeAsStringSync(timestampPem);

      final tsFile = File('$cacheDirectory/$_cacheTimestampFileName');
      tsFile.writeAsStringSync(DateTime.now().toUtc().toIso8601String());
    } catch (e) {
      debugPrint('[TrustListService] Cache write failed: $e');
    }
  }

  void _maybeRefreshInBackground() {
    try {
      final tsFile = File('$cacheDirectory/$_cacheTimestampFileName');
      if (!tsFile.existsSync()) {
        _fetchAndCache();
        return;
      }
      final tsStr = tsFile.readAsStringSync();
      final lastFetch = DateTime.tryParse(tsStr);
      if (lastFetch == null ||
          DateTime.now().toUtc().difference(lastFetch) > refreshInterval) {
        _fetchAndCache();
      }
    } catch (_) {
      _fetchAndCache();
    }
  }
}
