import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/music_search_result.dart';
import '../models/player_state.dart';
import '../services/music_search_service.dart';
import '../services/player/player_service.dart';

class PlayerController extends ChangeNotifier {
  PlayerController(this._service, this._musicSearchService);

  final PlayerService _service;
  final MusicSearchService _musicSearchService;
  StreamSubscription<PlayerState>? _sub;
  PlayerState state = const PlayerState();
  List<MusicSearchResult> searchResults = const [];
  bool isSearching = false;
  String? searchError;
  int _searchRequest = 0;

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

  void clearSearch() {
    _searchRequest++;
    isSearching = false;
    searchError = null;
    searchResults = const [];
    notifyListeners();
  }

  Future<void> searchTracks(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      _searchRequest++;
      searchError = 'Digite o nome de uma música ou artista.';
      searchResults = const [];
      isSearching = false;
      notifyListeners();
      return;
    }

    final request = ++_searchRequest;
    isSearching = true;
    searchError = null;
    searchResults = const [];
    notifyListeners();

    try {
      final results = await _musicSearchService.search(normalizedQuery);
      if (request != _searchRequest) return;
      searchResults = results;
    } on MusicSearchException catch (error) {
      if (request != _searchRequest) return;
      searchError = error.message;
    } catch (error, stackTrace) {
      if (request != _searchRequest) return;
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'music search',
        context: ErrorDescription('while searching for "$normalizedQuery"'),
      ));
      searchError = 'Não foi possível concluir a busca. Tente novamente.';
    } finally {
      if (request == _searchRequest) {
        isSearching = false;
        notifyListeners();
      }
    }
  }

  Future<void> playSearchResult(MusicSearchResult track) =>
      _service.playTrack(track);

  @override
  void dispose() {
    _searchRequest++;
    _sub?.cancel();
    _service.dispose();
    _musicSearchService.dispose();
    super.dispose();
  }
}
