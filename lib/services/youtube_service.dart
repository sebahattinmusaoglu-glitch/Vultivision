import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/channel.dart';
import '../models/video.dart';

class YouTubeService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  final Random _random = Random();

  String get _apiKey => dotenv.env['YOUTUBE_API_KEY'] ?? '';

  // Kanal arama (quota: 100 unit)
  Future<List<Channel>> searchChannels(String query) async {
    final uri = Uri.parse(
      '$_baseUrl/search'
      '?part=snippet'
      '&type=channel'
      '&q=${Uri.encodeComponent(query)}'
      '&maxResults=10'
      '&key=$_apiKey',
    );

    final response = await http.get(uri);
    _checkResponse(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items
        .map((item) => Channel.fromSearchJson(item as Map<String, dynamic>))
        .toList();
  }

  // Kanal detayı + abone sayısı (quota: 1 unit)
  Future<Channel> getChannelDetails(String channelId) async {
    final uri = Uri.parse(
      '$_baseUrl/channels'
      '?part=snippet,statistics,contentDetails'
      '&id=$channelId'
      '&key=$_apiKey',
    );

    final response = await http.get(uri);
    _checkResponse(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    if (items.isEmpty) throw Exception('Kanal bulunamadı');

    return Channel.fromDetailsJson(items.first as Map<String, dynamic>);
  }

  // Kanalın uploads playlist ID'sini al
  Future<String> _getUploadsPlaylistId(String channelId) async {
    final uri = Uri.parse(
      '$_baseUrl/channels'
      '?part=contentDetails'
      '&id=$channelId'
      '&key=$_apiKey',
    );

    final response = await http.get(uri);
    _checkResponse(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    if (items.isEmpty) throw Exception('Kanal bulunamadı');

    final contentDetails =
        (items.first as Map<String, dynamic>)['contentDetails']
            as Map<String, dynamic>;
    return contentDetails['relatedPlaylists']['uploads'] as String;
  }

  // Kanalın son videolarını getir (quota: 1 unit)
  Future<List<Video>> getChannelVideos(String channelId,
      {int maxResults = 50}) async {
    final playlistId = await _getUploadsPlaylistId(channelId);

    final uri = Uri.parse(
      '$_baseUrl/playlistItems'
      '?part=snippet'
      '&playlistId=$playlistId'
      '&maxResults=$maxResults'
      '&key=$_apiKey',
    );

    final response = await http.get(uri);
    _checkResponse(response);

    final data = json.decode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;

    return items
        .map((item) =>
            Video.fromPlaylistJson(item as Map<String, dynamic>))
        .where((v) => v.id.isNotEmpty)
        .toList();
  }

  // Birden fazla kanaldan rastgele video seç
  Future<Video> getRandomVideoFromChannels(List<Channel> channels) async {
    if (channels.isEmpty) throw Exception('Channel list is empty');

  // 3 deneme hakkı — farklı kanallar dene
  for (int attempt = 0; attempt < 3; attempt++) {
    try {
    final channel = channels[_random.nextInt(channels.length)];
    final videos = await getChannelVideos(channel.id);

   // Boş ID'leri filtrele
    final validVideos = videos
          .where((v) => v.id.isNotEmpty && v.id.length == 11)
          .toList();

    return validVideos[_random.nextInt(validVideos.length)];
    } catch (_) {
      continue;
    }
  }

  throw Exception('Could not load a valid video. Please try again.');
}

  void _checkResponse(http.Response response) {
    if (response.statusCode != 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      final error = body['error'] as Map<String, dynamic>?;
      final message = error?['message'] ?? 'Bilinmeyen hata';
      throw Exception('YouTube API hatası: $message');
    }
  }
}