import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/player_state.dart';
import '../services/player/player_service.dart';

class PlayerController extends ChangeNotifier {
  PlayerController(this._service);

  final PlayerService _service;
  StreamSubscription<PlayerState>? _sub;
  PlayerState state = const PlayerState();

  void init() {
    _sub = _service.stateStream.listen((s) {
      state = s;
      notifyListeners();
    });
    unawaited(_service.connect()); // não bloqueia a UI (tem retry interno)
  }

  void playPause() => _service.playPause();
  void next() => _service.next();
  void previous() => _service.previous();
  void seekTo(double s) => _service.seekTo(s);
  void changeVolume(int delta) =>
      _service.setVolume((state.volume + delta).clamp(0, 100).toInt());

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
