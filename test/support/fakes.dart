import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:car_hmi/models/player_state.dart';
import 'package:car_hmi/models/music_search_result.dart';
import 'package:car_hmi/services/map_service.dart';
import 'package:car_hmi/services/music_search_service.dart';
import 'package:car_hmi/services/player/player_service.dart';
import 'package:car_hmi/services/radio_service.dart';

class FakePlayerService implements PlayerService {
  final states = StreamController<PlayerState>.broadcast();
  final commands = <String>[];
  final volumes = <int>[];
  final seekPositions = <double>[];
  final playedTracks = <MusicSearchResult>[];
  int connectCalls = 0;
  bool disposed = false;

  void emit(PlayerState state) => states.add(state);

  @override
  Stream<PlayerState> get stateStream => states.stream;

  @override
  Future<void> connect() async => connectCalls++;

  @override
  Future<void> playPause() async => commands.add('playPause');

  @override
  Future<void> next() async => commands.add('next');

  @override
  Future<void> previous() async => commands.add('previous');

  @override
  Future<void> setVolume(int percent) async => volumes.add(percent);

  @override
  Future<void> seekTo(double seconds) async => seekPositions.add(seconds);

  @override
  Future<void> playTrack(MusicSearchResult track) async =>
      playedTracks.add(track);

  @override
  Future<void> dispose() async {
    disposed = true;
    await states.close();
  }
}

class FakeMusicSearchService implements MusicSearchService {
  final queries = <String>[];
  List<MusicSearchResult> results = const [];
  Object? error;
  bool disposed = false;
  Completer<List<MusicSearchResult>>? searchCompleter;

  @override
  Future<List<MusicSearchResult>> search(String query) {
    queries.add(query);
    final completer = searchCompleter;
    if (completer != null) return completer.future;
    final searchError = error;
    if (searchError != null) return Future.error(searchError);
    return Future.value(results);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeRadioService implements RadioService {
  final tunes = <(RadioBand, double)>[];
  final powers = <bool>[];
  final volumes = <int>[];
  final seeks = <(RadioBand, double, bool)>[];
  Completer<double>? seekCompleter;
  double seekResult = 98.5;
  bool disposed = false;

  @override
  Future<void> setPower(bool on) async => powers.add(on);

  @override
  Future<void> tune(RadioBand band, double frequency) async =>
      tunes.add((band, frequency));

  @override
  Future<double> seek(RadioBand band, double from, {required bool up}) {
    seeks.add((band, from, up));
    final completer = seekCompleter;
    if (completer != null) return completer.future;
    return Future.value(seekResult);
  }

  @override
  Future<void> setVolume(int percent) async => volumes.add(percent);

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeMapService implements MapService {
  FakeMapService([VehiclePosition? initial])
      : _current =
            initial ?? const VehiclePosition(LatLng(-23.55, -46.63), 45, 54);

  final _positions = StreamController<VehiclePosition>.broadcast();
  VehiclePosition _current;
  final ValueNotifier<String> _status = ValueNotifier('GPS de teste');
  bool disposed = false;

  void emit(VehiclePosition position) {
    _current = position;
    _positions.add(position);
  }

  @override
  VehiclePosition get current => _current;

  @override
  Stream<VehiclePosition> get positionStream => _positions.stream;

  @override
  ValueListenable<String> get status => _status;

  @override
  void dispose() {
    disposed = true;
    _positions.close();
    _status.dispose();
  }
}
