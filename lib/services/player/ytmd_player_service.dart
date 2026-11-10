import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../models/player_state.dart';
import 'player_service.dart';

class YtmdPlayerService implements PlayerService {
  YtmdPlayerService({
    this.host = '127.0.0.1',
    this.port = 9863,
    this.appId = 'car-hmi',
    this.appName = 'Car HMI',
    this.appVersion = '0.1.0',
  });

  final String host;
  final int port;
  final String appId;
  final String appName;
  final String appVersion;

  final _ctrl = StreamController<PlayerState>.broadcast();
  PlayerState _state = const PlayerState();
  String? _token;
  String? _memToken;
  io.Socket? _socket;
  Timer? _retry;
  bool _disposed = false;

  Uri _api(String path) => Uri.parse('http://$host:$port/api/v1$path');
  Map<String, String> get _json => {'Content-Type': 'application/json'};
  Map<String, String> get _authHeaders =>
      {..._json, if (_token != null) 'Authorization': _token!};

  @override
  Stream<PlayerState> get stateStream => _ctrl.stream;

  @override
  Future<void> connect() async {
    if (_disposed) return;
    try {
      _emit(_state.copyWith(message: 'Conectando ao YTMD…'));
      _token ??= await _loadToken();
      _token ??= await _pair();
      _openSocket();
    } catch (_) {
      _emit(_state.copyWith(
          connected: false, message: 'YTMD indisponível – tentando de novo'));
      _retry?.cancel();
      _retry = Timer(const Duration(seconds: 3), connect);
    }
  }

  // ---------- Token (memória + arquivo quando a plataforma permitir) ----------
  Future<String?> _loadToken() async {
    if (_memToken != null) return _memToken;
    try {
      final f = File('.ytmd_token');
      if (await f.exists()) {
        final t = (await f.readAsString()).trim();
        if (t.isNotEmpty) return _memToken = t;
      }
    } catch (_) {
      // Web: sem acesso a arquivo. O token fica só em memória.
    }
    return null;
  }

  Future<void> _saveToken(String t) async {
    _memToken = t;
    try {
      await File('.ytmd_token').writeAsString(t);
    } catch (_) {}
  }

  Future<void> _clearToken() async {
    _memToken = null;
    try {
      final f = File('.ytmd_token');
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ---------- Autenticação ----------
  Future<String> _pair() async {
    _emit(_state.copyWith(message: 'Aprove o pareamento na janela do YTMD…'));
    final codeRes = await http
        .post(_api('/auth/requestcode'),
            headers: _json,
            body: jsonEncode({
              'appId': appId,
              'appName': appName,
              'appVersion': appVersion,
            }))
        .timeout(const Duration(seconds: 5));
    if (codeRes.statusCode != 200) {
      throw Exception('requestcode ${codeRes.statusCode}');
    }
    final code = jsonDecode(codeRes.body)['code'] as String;

    // Fica pendente até o usuário aprovar no YTMD.
    final tokenRes = await http
        .post(_api('/auth/request'),
            headers: _json, body: jsonEncode({'appId': appId, 'code': code}))
        .timeout(const Duration(seconds: 60));
    if (tokenRes.statusCode != 200) {
      throw Exception('request ${tokenRes.statusCode}');
    }
    final token = jsonDecode(tokenRes.body)['token'] as String;
    await _saveToken(token);
    return token;
  }

  Future<void> _resetAuth() async {
    _token = null;
    _socket?.dispose();
    await _clearToken();
    await connect();
  }

  // ---------- Tempo real ----------
  void _openSocket() {
    _socket?.dispose();
    final s = io.io(
      'http://$host:$port/api/v1/realtime',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _token})
          .enableReconnection()
          .build(),
    );

    s.onConnect((_) =>
        _emit(_state.copyWith(connected: true, message: 'YTMD conectado')));
    s.onDisconnect((_) =>
        _emit(_state.copyWith(connected: false, message: 'YTMD desconectado')));
    s.onConnectError((err) {
      if ('$err'.toLowerCase().contains('unauthorized')) _resetAuth();
    });
    s.on('state-update', (data) {
      if (data is Map) _applyState(data);
    });

    _socket = s;
  }

  void _applyState(Map data) {
    final player = (data['player'] as Map?) ?? const {};
    final video = data['video'] as Map?;
    final trackState = (player['trackState'] as num?)?.toInt() ?? -1;

    TrackInfo? track;
    if (video != null) {
      final thumbs = (video['thumbnails'] as List?) ?? const [];
      track = TrackInfo(
        title: (video['title'] as String?) ?? '',
        artist: (video['author'] as String?) ?? '',
        album: (video['album'] as String?) ?? '',
        artUrl:
            thumbs.isNotEmpty ? (thumbs.last as Map)['url'] as String? : null,
        durationSec: (video['durationSeconds'] as num?)?.toDouble() ?? 0,
      );
    }

    _emit(PlayerState(
      status: switch (trackState) {
        1 => PlaybackStatus.playing,
        0 => PlaybackStatus.paused,
        2 => PlaybackStatus.buffering,
        _ => PlaybackStatus.stopped,
      },
      track: track,
      positionSec: (player['videoProgress'] as num?)?.toDouble() ?? 0,
      volume: (player['volume'] as num?)?.round() ?? _state.volume,
      connected: true,
      message: 'YTMD conectado',
    ));
  }

  // ---------- Comandos ----------
  Future<void> _command(String command, [Object? data]) async {
    if (_token == null) return;
    try {
      final res = await http
          .post(_api('/command'),
              headers: _authHeaders,
              body: jsonEncode(
                  {'command': command, if (data != null) 'data': data}))
          .timeout(const Duration(seconds: 3));
      if (res.statusCode == 401) await _resetAuth();
    } catch (_) {
      // Offline: o socket reconecta sozinho e o estado volta a sincronizar.
    }
  }

  @override
  Future<void> playPause() => _command('playPause');
  @override
  Future<void> next() => _command('next');
  @override
  Future<void> previous() => _command('previous');
  @override
  Future<void> seekTo(double seconds) => _command('seekTo', seconds);

  @override
  Future<void> setVolume(int percent) {
    _emit(_state.copyWith(volume: percent)); // otimista: a UI responde na hora
    return _command('setVolume', percent);
  }

  void _emit(PlayerState s) {
    _state = s;
    if (!_ctrl.isClosed) _ctrl.add(s);
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _retry?.cancel();
    _socket?.dispose();
    await _ctrl.close();
  }
}
