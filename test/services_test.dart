import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:car_hmi/models/player_state.dart';
import 'package:car_hmi/services/gps_map_service.dart';
import 'package:car_hmi/services/map_service.dart';
import 'package:car_hmi/services/player/mock_player_service.dart';
import 'package:car_hmi/services/player/ytmd_player_service.dart';
import 'package:car_hmi/services/radio_service.dart';

void main() {
  group('MockPlayerService', () {
    late MockPlayerService service;
    late StreamSubscription<PlayerState> subscription;
    late List<PlayerState> states;

    setUp(() {
      service = MockPlayerService();
      states = [];
      subscription = service.stateStream.listen(states.add);
    });

    tearDown(() async {
      await subscription.cancel();
      await service.dispose();
    });

    test('connect emits the first track in playing state', () async {
      await service.connect();
      await Future<void>.delayed(Duration.zero);

      expect(states, hasLength(1));
      expect(states.single.track?.title, 'Estrada Aberta');
      expect(states.single.status, PlaybackStatus.playing);
      expect(states.single.connected, isTrue);
    });

    test('playback commands change state and wrap track navigation', () async {
      await service.connect();
      await service.playPause();
      await service.next();
      await service.previous();
      await Future<void>.delayed(Duration.zero);

      expect(states[1].status, PlaybackStatus.paused);
      expect(states[2].track?.title, 'Noite na Serra');
      expect(states[3].track?.title, 'Estrada Aberta');

      await service.previous();
      await Future<void>.delayed(Duration.zero);
      expect(states.last.track?.title, 'Horizonte');
    });

    test('updates volume and playback position', () async {
      await service.connect();
      await service.setVolume(35);
      await service.seekTo(75.5);
      await Future<void>.delayed(Duration.zero);

      expect(states[1].volume, 35);
      expect(states[2].positionSec, 75.5);
    });
  });

  group('MockMapService', () {
    test('provides simulated São Paulo position and speed in km/h', () {
      final service = MockMapService();
      addTearDown(service.dispose);

      expect(service.current.latLng, const LatLng(-23.5505, -46.6333));
      expect(service.current.heading, 45);
      expect(service.current.speedKmh, 54);
      expect(service.status.value, 'Posição simulada');
    });

    test('emits simulated positions and changes heading', () async {
      final service = MockMapService();
      addTearDown(service.dispose);

      final positionFuture = service.positionStream.first;
      final position = await positionFuture.timeout(const Duration(seconds: 2));

      expect(position.latLng, isNot(const LatLng(-23.5505, -46.6333)));
      expect(position.heading, 48);
      expect(position.speedKmh, 54);
    });
  });

  group('GpsMapService', () {
    test('provides an initial position and a platform status', () {
      final service = GpsMapService();
      addTearDown(service.dispose);

      expect(service.current.latLng, const LatLng(-23.5505, -46.6333));
      expect(service.status.value, isNotEmpty);
    });
  });

  group('YtmdPlayerService', () {
    test('updates volume optimistically and safely ignores commands offline',
        () async {
      final service = YtmdPlayerService(host: '127.0.0.1', port: 0);
      final firstState = service.stateStream.first;

      await service.setVolume(65);
      expect((await firstState).volume, 65);

      await service.playPause();
      await service.next();
      await service.previous();
      await service.seekTo(12.5);
      await service.dispose();
    });
  });

  group('MockRadioService', () {
    test('seeks to next and previous available FM stations with wrap-around',
        () async {
      final service = MockRadioService();

      expect(await service.seek(RadioBand.fm, 98.5, up: true), 101.1);
      expect(await service.seek(RadioBand.fm, 107.3, up: true), 88.3);
      expect(await service.seek(RadioBand.fm, 88.3, up: false), 107.3);
    });

    test('seeks through AM stations', () async {
      final service = MockRadioService();

      expect(await service.seek(RadioBand.am, 1020, up: true), 1230);
      expect(await service.seek(RadioBand.am, 560, up: false), 1450);
    });
  });
}
