import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:car_hmi/services/music_search_service.dart';

void main() {
  test('searches relevant music videos and parses results and thumbnails',
      () async {
    late Uri requestUri;
    final client = MockClient((request) async {
      requestUri = request.url;
      return http.Response(
        jsonEncode({
          'items': [
            {
              'id': {'videoId': 'video-1'},
              'snippet': {
                'title': 'Música desejada',
                'channelTitle': 'Artista',
                'thumbnails': {
                  'default': {'url': 'https://example.com/small.jpg'},
                  'high': {'url': 'https://example.com/high.jpg'},
                },
              },
            },
            {
              'id': {'videoId': 'video-2'},
              'snippet': {'title': 'Outro resultado'},
            },
            {
              'id': {},
              'snippet': {'title': 'Item inválido'},
            },
          ],
        }),
        200,
      );
    });
    final service =
        YouTubeMusicSearchService(apiKey: 'restricted-key', client: client);
    addTearDown(service.dispose);

    final results = await service.search('  música artista  ');

    expect(requestUri.host, 'www.googleapis.com');
    expect(requestUri.path, '/youtube/v3/search');
    expect(requestUri.queryParameters['q'], 'música artista');
    expect(requestUri.queryParameters['videoCategoryId'], '10');
    expect(requestUri.queryParameters['order'], 'relevance');
    expect(requestUri.queryParameters['maxResults'], '10');
    expect(requestUri.queryParameters['key'], 'restricted-key');
    expect(results, hasLength(2));
    expect(results.first.videoId, 'video-1');
    expect(results.first.title, 'Música desejada');
    expect(results.first.artist, 'Artista');
    expect(results.first.thumbnailUrl, 'https://example.com/high.jpg');
    expect(results.last.artist, 'Artista desconhecido');
    expect(results.last.thumbnailUrl, isNull);
  });

  test('does not make a request for an empty query', () async {
    var requests = 0;
    final service = YouTubeMusicSearchService(
      apiKey: 'restricted-key',
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(service.dispose);

    expect(await service.search('   '), isEmpty);
    expect(requests, 0);
  });

  test('reports missing API key without making a network request', () async {
    var requests = 0;
    final service = YouTubeMusicSearchService(
      apiKey: '',
      client: MockClient((_) async {
        requests++;
        return http.Response('{}', 200);
      }),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.search('artista'),
      throwsA(
        isA<MusicSearchException>().having(
          (error) => error.message,
          'message',
          contains('configure uma chave'),
        ),
      ),
    );
    expect(requests, 0);
  });

  test('explains API quota and configuration errors', () async {
    final service = YouTubeMusicSearchService(
      apiKey: 'restricted-key',
      client: MockClient((_) async => http.Response('{}', 403)),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.search('artista'),
      throwsA(
        isA<MusicSearchException>().having(
          (error) => error.message,
          'message',
          contains('cota'),
        ),
      ),
    );
  });
}
