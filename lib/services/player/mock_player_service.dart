import 'dart:async';

import '../../models/music_search_result.dart';
import '../../models/player_state.dart';
import 'player_service.dart';

class MockPlayerService implements PlayerService {
  static const _tracks = [
    TrackInfo(
        title: 'Estrada Aberta',
        artist: 'Banda Mock',
        album: 'Highway',
        durationSec: 214),
    TrackInfo(
        title: 'Noite na Serra',
        artist: 'Artista Teste',
        album: 'Curvas',
        durationSec: 187),
    TrackInfo(
        title: 'Horizonte',
        artist: 'Dev Band',
        album: 'Kernel',
        durationSec: 241),
  ];

  final _ctrl = StreamController<PlayerState>.broadcast();
  PlayerState _s =
      const PlayerState(connected: true, message: 'Player simulado');
  int _i = 0;
  Timer? _timer;

  @override
  Stream<PlayerState> get stateStream => _ctrl.stream;

  @override
  Future<void> connect() async {
    _s = _s.copyWith(track: _tracks[_i], status: PlaybackStatus.playing);
    _ctrl.add(_s);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_s.status != PlaybackStatus.playing) return;
      final pos = _s.positionSec + 1;
      if (pos >= _s.track!.durationSec) {
        next();
      } else {
        _emit(_s.copyWith(positionSec: pos));
      }
    });
  }

  void _emit(PlayerState s) {
    _s = s;
    _ctrl.add(s);
  }

  @override
  Future<void> playPause() async => _emit(_s.copyWith(
      status: _s.status == PlaybackStatus.playing
          ? PlaybackStatus.paused
          : PlaybackStatus.playing));

  @override
  Future<void> next() async {
    _i = (_i + 1) % _tracks.length;
    _emit(_s.copyWith(track: _tracks[_i], positionSec: 0));
  }

  @override
  Future<void> previous() async {
    _i = (_i - 1 + _tracks.length) % _tracks.length;
    _emit(_s.copyWith(track: _tracks[_i], positionSec: 0));
  }

  @override
  Future<void> setVolume(int percent) async =>
      _emit(_s.copyWith(volume: percent));

  @override
  Future<void> seekTo(double seconds) async =>
      _emit(_s.copyWith(positionSec: seconds));

  @override
  Future<void> playTrack(MusicSearchResult track) async => _emit(
        _s.copyWith(
          track: TrackInfo(
            title: track.title,
            artist: track.artist,
            artUrl: track.thumbnailUrl,
          ),
          status: PlaybackStatus.playing,
          positionSec: 0,
          connected: true,
        ),
      );

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _ctrl.close();
  }
}
