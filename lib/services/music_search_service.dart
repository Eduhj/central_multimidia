import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/music_search_result.dart';

abstract class MusicSearchService {
  Future<List<MusicSearchResult>> search(String query);
  Future<void> dispose();
}

class YouTubeMusicSearchService implements MusicSearchService {
  YouTubeMusicSearchService({
    required this.apiKey,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final String apiKey;
  final http.Client _client;
  final bool _ownsClient;

  @override
  Future<List<MusicSearchResult>> search(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return const [];
    if (apiKey.isEmpty) {
      throw const MusicSearchException(
        'Busca indisponível: configure uma chave restrita da YouTube Data API.',
      );
    }

    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'type': 'video',
      'videoCategoryId': '10',
      'order': 'relevance',
      'maxResults': '10',
      'q': normalizedQuery,
      'key': apiKey,
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw MusicSearchException(switch (response.statusCode) {
        403 =>
          'A busca foi recusada. Verifique a chave, as restrições e a cota da YouTube Data API.',
        400 => 'A busca foi rejeitada pela YouTube Data API.',
        _ => 'A busca falhou (HTTP ${response.statusCode}). Tente novamente.',
      });
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic> || decoded['items'] is! List) {
      throw const MusicSearchException(
        'A resposta da busca veio em um formato inválido.',
      );
    }

    return (decoded['items'] as List)
        .whereType<Map<String, dynamic>>()
        .map(_parseResult)
        .whereType<MusicSearchResult>()
        .toList(growable: false);
  }

  MusicSearchResult? _parseResult(Map<String, dynamic> item) {
    final id = item['id'];
    final snippet = item['snippet'];
    if (id is! Map<String, dynamic> ||
        snippet is! Map<String, dynamic> ||
        id['videoId'] is! String ||
        snippet['title'] is! String) {
      return null;
    }

    final thumbnails = snippet['thumbnails'];
    String? thumbnailUrl;
    if (thumbnails is Map<String, dynamic>) {
      for (final size in ['high', 'medium', 'default']) {
        final thumbnail = thumbnails[size];
        if (thumbnail is Map<String, dynamic> && thumbnail['url'] is String) {
          thumbnailUrl = thumbnail['url'] as String;
          break;
        }
      }
    }

    return MusicSearchResult(
      videoId: id['videoId'] as String,
      title: snippet['title'] as String,
      artist: snippet['channelTitle'] as String? ?? 'Artista desconhecido',
      thumbnailUrl: thumbnailUrl,
    );
  }

  @override
  Future<void> dispose() async {
    if (_ownsClient) _client.close();
  }
}

class MusicSearchException implements Exception {
  const MusicSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}
