import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:car_hmi/controllers/nav_controller.dart';
import 'package:car_hmi/controllers/player_controller.dart';
import 'package:car_hmi/controllers/radio_controller.dart';
import 'package:car_hmi/models/music_search_result.dart';
import 'package:car_hmi/models/player_state.dart';
import 'package:car_hmi/services/map_service.dart';
import 'package:car_hmi/services/music_search_service.dart';
import 'package:car_hmi/services/radio_service.dart';

import 'support/fakes.dart';

void main() {
  group('PlayerController', () {
    late FakePlayerService service;
    late FakeMusicSearchService searchService;
    late PlayerController controller;
    var disposed = false;

    setUp(() {
      service = FakePlayerService();
      searchService = FakeMusicSearchService();
      controller = PlayerController(service, searchService);
      disposed = false;
    });

    tearDown(() {
      if (!disposed) controller.dispose();
    });

    test('subscribes to player state and connects without blocking', () async {
      controller.init();
      expect(service.connectCalls, 1);
      expect(controller.state.status, PlaybackStatus.stopped);

      const state = PlayerState(
        status: PlaybackStatus.playing,
        positionSec: 30,
        connected: true,
      );
      service.emit(state);
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, same(state));
    });

    test('forwards playback and seek commands', () async {
      controller.playPause();
      controller.previous();
      controller.next();
      controller.seekTo(42.5);

      expect(service.commands, ['playPause', 'previous', 'next']);
      expect(service.seekPositions, [42.5]);
    });

    test('clamps volume to the supported range', () async {
      controller.changeVolume(100);
      controller.changeVolume(-200);

      expect(service.volumes, [100, 0]);
    });

    test('cancels its subscription and disposes its service', () async {
      controller.init();
      controller.dispose();
      disposed = true;
      await Future<void>.delayed(Duration.zero);

      expect(service.disposed, isTrue);
      expect(searchService.disposed, isTrue);
    });

    test('searches normalized queries and plays a selected result', () async {
      const result = MusicSearchResult(
        videoId: 'video-123',
        title: 'Canção',
        artist: 'Artista',
      );
      searchService.results = const [result];

      await controller.searchTracks('  Canção  ');
      expect(searchService.queries, ['Canção']);
      expect(controller.searchResults, [result]);
      expect(controller.isSearching, isFalse);
      expect(controller.searchError, isNull);

      await controller.playSearchResult(result);
      expect(service.playedTracks, [result]);
    });

    test('reports empty queries and search errors to the interface', () async {
      final pendingSearch = Completer<List<MusicSearchResult>>();
      searchService.searchCompleter = pendingSearch;
      final pendingRequest = controller.searchTracks('consulta em andamento');
      await controller.searchTracks('   ');
      expect(controller.searchError, 'Digite o nome de uma música ou artista.');
      pendingSearch.complete(const []);
      await pendingRequest;
      expect(controller.searchError, 'Digite o nome de uma música ou artista.');

      searchService.searchCompleter = null;
      expect(searchService.queries, ['consulta em andamento']);

      searchService.error = const MusicSearchException('Cota excedida.');
      await controller.searchTracks('artista');
      expect(controller.searchError, 'Cota excedida.');
      expect(controller.isSearching, isFalse);
    });

    test('ignores stale results when a newer search finishes first', () async {
      final olderSearch = Completer<List<MusicSearchResult>>();
      final newerSearch = Completer<List<MusicSearchResult>>();
      searchService.searchCompleter = olderSearch;
      final olderRequest = controller.searchTracks('antiga');

      searchService.searchCompleter = newerSearch;
      final newerRequest = controller.searchTracks('nova');
      const latest = MusicSearchResult(
        videoId: 'latest',
        title: 'Resultado atual',
        artist: 'Artista',
      );
      newerSearch.complete(const [latest]);
      await newerRequest;

      olderSearch.complete(const []);
      await olderRequest;
      expect(controller.searchResults, const [latest]);
    });
  });

  group('RadioController', () {
    late FakeRadioService service;
    late RadioController controller;
    var disposed = false;

    setUp(() {
      service = FakeRadioService();
      controller = RadioController(service);
      disposed = false;
    });

    tearDown(() {
      if (!disposed) controller.dispose();
    });

    test('starts on FM and retains each band frequency', () async {
      expect(controller.band, RadioBand.fm);
      expect(controller.frequency, 98.5);
      expect(controller.volume, 40);

      await controller.setBand(RadioBand.am);
      expect(controller.frequency, 1020);
      await controller.setBand(RadioBand.fm);
      expect(controller.frequency, 98.5);
      expect(service.tunes, [(RadioBand.am, 1020.0), (RadioBand.fm, 98.5)]);
    });

    test('steps and wraps frequencies at both ends of FM', () async {
      controller.presets[RadioBand.fm]![0] = RadioBand.fm.min;
      await controller.tunePreset(0);
      await controller.step(-1);
      expect(controller.frequency, RadioBand.fm.max);

      await controller.step(1);
      expect(controller.frequency, 87.5);
    });

    test('tunes presets and leaves empty presets unchanged', () async {
      await controller.tunePreset(0);
      expect(controller.frequency, 88.3);
      await controller.tunePreset(3);
      expect(controller.frequency, 88.3);
      expect(controller.isPresetActive(0), isTrue);

      controller.savePreset(3);
      expect(controller.presets[RadioBand.fm]![3], 88.3);
      expect(controller.isPresetActive(3), isTrue);
    });

    test('prevents concurrent seeks and clears seeking when completed',
        () async {
      final seekCompleter = Completer<double>();
      service.seekCompleter = seekCompleter;

      final pending = controller.seek(up: true);
      expect(controller.seeking, isTrue);
      await controller.seek(up: false);
      expect(service.seeks, [(RadioBand.fm, 98.5, true)]);

      seekCompleter.complete(101.1);
      await pending;
      expect(controller.seeking, isFalse);
      expect(controller.frequency, 101.1);
      expect(service.tunes.last, (RadioBand.fm, 101.1));
    });

    test('clamps volume and notifies the service when toggling power',
        () async {
      await controller.changeVolume(100);
      await controller.changeVolume(-200);
      await controller.togglePower();
      await controller.togglePower();

      expect(controller.volume, 0);
      expect(service.volumes, [100, 0]);
      expect(controller.power, isTrue);
      expect(service.powers, [false, true]);
    });

    test('notifies listeners for state changes', () async {
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.step(1);
      expect(notifications, 1);
      await controller.togglePower();
      expect(notifications, 2);
    });

    test('disposes the service', () {
      controller.dispose();
      disposed = true;
      expect(service.disposed, isTrue);
    });
  });

  group('NavController', () {
    late FakeMapService service;
    late NavController controller;
    var disposed = false;

    setUp(() {
      service = FakeMapService();
      controller = NavController(service);
      disposed = false;
    });

    tearDown(() {
      if (!disposed) controller.dispose();
    });

    test('initializes from current position and exposes GPS status', () {
      expect(controller.position, const LatLng(-23.55, -46.63));
      expect(controller.gpsStatus.value, 'GPS de teste');
      expect(controller.heading, 0);
      expect(controller.speedKmh, 0);
      expect(controller.follow, isTrue);
    });

    test('updates position and vehicle data from the position stream',
        () async {
      controller.init();
      const position = VehiclePosition(LatLng(-22.9, -43.2), 120, 35);

      service.emit(position);
      await Future<void>.delayed(Duration.zero);

      expect(controller.position, position.latLng);
      expect(controller.heading, 120);
      expect(controller.speedKmh, 35);
    });

    test('user gesture disables follow and recenter re-enables it', () {
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.onUserGesture();
      expect(controller.follow, isFalse);
      expect(notifications, 1);

      controller.onUserGesture();
      expect(notifications, 1);

      controller.recenter();
      expect(controller.follow, isTrue);
      expect(notifications, 2);
    });

    test('zoom is safe before the map is ready', () {
      expect(() => controller.zoom(1), returnsNormally);
    });

    test('disposes its stream subscription and map service', () async {
      controller.init();
      controller.dispose();
      disposed = true;
      await Future<void>.delayed(Duration.zero);

      expect(service.disposed, isTrue);
    });
  });
}
