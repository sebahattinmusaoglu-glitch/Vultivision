import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/video.dart';
import 'auth_service.dart';

/// YouTube Data API v3 servisi.
/// - API key  → search, kanal detayı, video yükleme (auth gerektirmez)
/// - OAuth    → abonelikler (authService gerektirir)
class YouTubeService {
  final AuthService? _authService;

  static const _base = 'https://www.googleapis.com/youtube/v3';
  static const _maxRetries = 2;

  /// [authService] yalnızca OAuth gerektiren metodlar için gereklidir
  /// (getSubscriptions). Diğer metodlar API key ile çalışır.
  YouTubeService({AuthService? authService}) : _authService = authService;

  // ─── Yardımcılar ────────────────────────────────────────────────────────

  String get _apiKey {
    final key = dotenv.env['YOUTUBE_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw YouTubeConfigException('YOUTUBE_API_KEY .env dosyasında bulunamadı.');
    }
    return key;
  }

  Uri _apiUri(String endpoint, Map<String, String> params) {
    return Uri.parse('$_base/$endpoint').replace(
      queryParameters: {...params, 'key': _apiKey},
    );
  }

  Future<Map<String, dynamic>> _get(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 401) {
      throw YouTubeAuthException('Token geçersiz veya süresi dolmuş.');
    }
    if (response.statusCode == 403) {
      throw YouTubeQuotaException('API kotası aşıldı veya erişim reddedildi.');
    }
    if (response.statusCode != 200) {
      throw YouTubeApiException(
        'API hatası: ${response.statusCode}',
        response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, String>> _oauthHeaders() async {
    if (_authService == null) {
      throw YouTubeAuthException('OAuth için AuthService gereklidir.');
    }
    final token = await _authService!.getYouTubeAccessToken();
    if (token == null) {
      throw YouTubeAuthException(
        'Access token alınamadı — kullanıcı giriş yapmamış olabilir.',
      );
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // ─── Kanal arama (API key) ───────────────────────────────────────────────

  /// Sorguya göre YouTube kanallarını arar.
  Future<List<Channel>> searchChannels(String query) async {
    final uri = _apiUri('search', {
      'part': 'snippet',
      'type': 'channel',
      'q': query,
      'maxResults': '10',
    });

    final data = await _get(uri);
    final items = data['items'] as List? ?? [];

    return items
        .map((item) => Channel.fromSearchJson(item))
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  // ─── Kanal detayı (API key) ──────────────────────────────────────────────

  /// Tek bir kanalın snippet + statistics detayını döner.
  Future<Channel> getChannelDetails(String channelId) async {
    final uri = _apiUri('channels', {
      'part': 'snippet,statistics',
      'id': channelId,
    });

    final data = await _get(uri);
    final items = data['items'] as List?;

    if (items == null || items.isEmpty) {
      throw YouTubeApiException('Kanal bulunamadı: $channelId', 404);
    }
    return Channel.fromDetailsJson(items.first);
  }

  // ─── Rastgele video (API key) ────────────────────────────────────────────

  /// Verilen kanal listesinden rastgele bir video seçer.
  /// Kanal boş çıkarsa başka bir kanal dener (maks [_maxRetries] kez).
  Future<Video> getRandomVideoFromChannels(List<Channel> channels) async {
    if (channels.isEmpty) {
      throw YouTubeApiException('Kanal listesi boş.', 400);
    }

    final rng = Random();
    final shuffled = [...channels]..shuffle(rng);

    for (var i = 0; i < min(shuffled.length, _maxRetries + 1); i++) {
      try {
        final channel = shuffled[i];
        final videos = await _getChannelVideos(channel.id);
        if (videos.isNotEmpty) {
          return videos[rng.nextInt(videos.length)];
        }
      } catch (_) {
        continue; // Sonraki kanala geç
      }
    }
    throw YouTubeApiException('Hiçbir kanalda video bulunamadı.', 404);
  }

  /// Kanalın son yüklemelerini döner (upload playlist üzerinden).
  Future<List<Video>> _getChannelVideos(
    String channelId, {
    int maxResults = 30,
  }) async {
    // 1. Upload playlist ID'sini al
    final channelUri = _apiUri('channels', {
      'part': 'contentDetails',
      'id': channelId,
    });
    final channelData = await _get(channelUri);
    final uploadPlaylistId = channelData['items']?[0]?['contentDetails']
        ?['relatedPlaylists']?['uploads'] as String?;

    if (uploadPlaylistId == null) return [];

    // 2. Playlist öğelerini çek
    final playlistUri = _apiUri('playlistItems', {
      'part': 'snippet',
      'playlistId': uploadPlaylistId,
      'maxResults': '$maxResults',
    });
    final playlistData = await _get(playlistUri);

    return (playlistData['items'] as List? ?? [])
        .map((item) => Video.fromPlaylistJson(item))
        .where((v) => v.id.isNotEmpty)
        .toList();
  }

  // ─── Abonelikler (OAuth) ─────────────────────────────────────────────────

  /// Giriş yapmış kullanıcının abone olduğu kanalları döner.
  /// Gereksinim: constructor'a [authService] verilmiş olmalı.
  Future<List<Channel>> getSubscriptions({int maxResults = 50}) async {
    final headers = await _oauthHeaders();
    final uri = Uri.parse(
      '$_base/subscriptions'
      '?part=snippet'
      '&mine=true'
      '&maxResults=$maxResults'
      '&order=alphabetical',
    );

    final data = await _get(uri, headers: headers);
    return (data['items'] as List? ?? [])
        .map((item) => _channelFromSubscriptionItem(item))
        .toList();
  }

  Channel _channelFromSubscriptionItem(Map<String, dynamic> item) {
    final snippet = item['snippet'] as Map<String, dynamic>;
    final resourceId = snippet['resourceId'] as Map<String, dynamic>;
    final thumbs = snippet['thumbnails'] as Map<String, dynamic>?;
    final thumbUrl =
        (thumbs?['medium'] ?? thumbs?['default'])?['url'] as String? ?? '';

    return Channel(
      id: resourceId['channelId'] as String,
      title: snippet['title'] as String,
      thumbnailUrl: thumbUrl,
      subscriberCount: '',
    );
  }
}

// ─── İstisnalar ─────────────────────────────────────────────────────────────

class YouTubeConfigException implements Exception {
  final String message;
  const YouTubeConfigException(this.message);
  @override
  String toString() => 'YouTubeConfigException: $message';
}

class YouTubeAuthException implements Exception {
  final String message;
  const YouTubeAuthException(this.message);
  @override
  String toString() => 'YouTubeAuthException: $message';
}

class YouTubeQuotaException implements Exception {
  final String message;
  const YouTubeQuotaException(this.message);
  @override
  String toString() => 'YouTubeQuotaException: $message';
}

class YouTubeApiException implements Exception {
  final String message;
  final int statusCode;
  const YouTubeApiException(this.message, this.statusCode);
  @override
  String toString() => 'YouTubeApiException($statusCode): $message';
}