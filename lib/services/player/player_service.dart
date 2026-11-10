import '../../../models/player_state.dart';

/// Contrato único. Implementações: YTMD (agora), Mopidy / MPRIS (Linux) depois.
abstract class PlayerService {
  Stream<PlayerState> get stateStream;
  Future<void> connect();
  Future<void> playPause();
  Future<void> next();
  Future<void> previous();
  Future<void> setVolume(int percent);
  Future<void> seekTo(double seconds);
  Future<void> dispose();
}
