enum PlaybackStatus { stopped, paused, playing, buffering }

class TrackInfo {
  const TrackInfo({
    required this.title,
    required this.artist,
    this.album = '',
    this.artUrl,
    this.durationSec = 0,
  });

  final String title;
  final String artist;
  final String album;
  final String? artUrl;
  final double durationSec;

  // Igualdade por valor: evita rebuild da capa/título a cada state-update.
  @override
  bool operator ==(Object other) =>
      other is TrackInfo &&
      other.title == title &&
      other.artist == artist &&
      other.album == album &&
      other.artUrl == artUrl &&
      other.durationSec == durationSec;

  @override
  int get hashCode => Object.hash(title, artist, album, artUrl, durationSec);
}

class PlayerState {
  const PlayerState({
    this.status = PlaybackStatus.stopped,
    this.track,
    this.positionSec = 0,
    this.volume = 50,
    this.connected = false,
    this.message = 'Conectando…',
  });

  final PlaybackStatus status;
  final TrackInfo? track;
  final double positionSec;
  final int volume;
  final bool connected;
  final String message;

  PlayerState copyWith({
    PlaybackStatus? status,
    TrackInfo? track,
    double? positionSec,
    int? volume,
    bool? connected,
    String? message,
  }) =>
      PlayerState(
        status: status ?? this.status,
        track: track ?? this.track,
        positionSec: positionSec ?? this.positionSec,
        volume: volume ?? this.volume,
        connected: connected ?? this.connected,
        message: message ?? this.message,
      );
}
