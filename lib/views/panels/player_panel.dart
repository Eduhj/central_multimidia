import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/player_controller.dart';
import '../../core/app_theme.dart';
import '../../core/format.dart';
import '../../models/music_search_result.dart';
import '../../models/player_state.dart';
import '../widgets/big_button.dart';
import '../widgets/volume_bar.dart';

class PlayerPanel extends StatelessWidget {
  const PlayerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.read<PlayerController>();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: _NowPlaying()),
              IconButton(
                tooltip: 'Pesquisar músicas',
                onPressed: () {
                  c.clearSearch();
                  showDialog<void>(
                    context: context,
                    builder: (_) => _MusicSearchDialog(controller: c),
                  );
                },
                icon: const Icon(Icons.search),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _ProgressBar(),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BigButton(
                  width: 96,
                  height: 96,
                  onPressed: c.previous,
                  child: const Icon(Icons.skip_previous, size: 52)),
              Selector<PlayerController, PlaybackStatus>(
                selector: (_, c) => c.state.status,
                builder: (_, status, __) => BigButton(
                  width: 128,
                  height: 128,
                  filled: true,
                  onPressed: c.playPause,
                  child: Icon(
                      status == PlaybackStatus.playing
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 72),
                ),
              ),
              BigButton(
                  width: 96,
                  height: 96,
                  onPressed: c.next,
                  child: const Icon(Icons.skip_next, size: 52)),
            ],
          ),
          const Spacer(),
          Selector<PlayerController, int>(
            selector: (_, c) => c.state.volume,
            builder: (_, v, __) => VolumeBar(
                value: v,
                onDown: () => c.changeVolume(-5),
                onUp: () => c.changeVolume(5)),
          ),
        ],
      ),
    );
  }
}

class _MusicSearchDialog extends StatefulWidget {
  const _MusicSearchDialog({required this.controller});

  final PlayerController controller;

  @override
  State<_MusicSearchDialog> createState() => _MusicSearchDialogState();
}

class _MusicSearchDialogState extends State<_MusicSearchDialog> {
  final _queryController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _submitted = true);
    await widget.controller.searchTracks(_queryController.text);
  }

  Future<void> _play(MusicSearchResult result) async {
    try {
      await widget.controller.playSearchResult(result);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível reproduzir: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Pesquisar músicas'),
        content: SizedBox(
          width: 520,
          height: 520,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _search(),
                      decoration: const InputDecoration(
                        hintText: 'Nome da música ou artista',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Buscar',
                    onPressed: _search,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Consumer<PlayerController>(
                  builder: (context, controller, _) {
                    if (controller.isSearching) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (controller.searchError case final error?) {
                      return Center(
                        child: Text(
                          error,
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    if (controller.searchResults.isEmpty) {
                      return Center(
                        child: Text(
                          _submitted
                              ? 'Nenhuma música encontrada.'
                              : 'Pesquise por música ou artista.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: controller.searchResults.length,
                      itemBuilder: (context, index) {
                        final result = controller.searchResults[index];
                        return ListTile(
                          leading: SizedBox(
                            width: 64,
                            child: result.thumbnailUrl == null
                                ? const Icon(Icons.music_note)
                                : Image.network(
                                    result.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.music_note),
                                  ),
                          ),
                          title: Text(
                            result.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            result.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: 'Reproduzir ${result.title}',
                            onPressed: controller.state.connected
                                ? () => _play(result)
                                : null,
                            icon: const Icon(Icons.play_arrow),
                          ),
                          onTap: controller.state.connected
                              ? () => _play(result)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              if (!widget.controller.state.connected)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Conecte-se ao YTMD para reproduzir os resultados.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      );
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying();

  @override
  Widget build(BuildContext context) {
    final track =
        context.select<PlayerController, TrackInfo?>((c) => c.state.track);
    final msg =
        context.select<PlayerController, String>((c) => c.state.message);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 140,
            height: 140,
            child: track?.artUrl != null
                ? Image.network(track!.artUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _ArtPlaceholder())
                : const _ArtPlaceholder(),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: track == null
              ? Text(msg,
                  style:
                      const TextStyle(fontSize: 22, color: AppColors.textDim))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.15)),
                    const SizedBox(height: 6),
                    Text(track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 22, color: AppColors.accent)),
                    if (track.album.isNotEmpty)
                      Text(track.album,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 18, color: AppColors.textDim)),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ArtPlaceholder extends StatelessWidget {
  const _ArtPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
        color: AppColors.surfaceHigh,
        child: const Icon(Icons.music_note, size: 64, color: AppColors.textDim),
      );
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar();

  @override
  Widget build(BuildContext context) {
    final (pos, dur) = context.select<PlayerController, (double, double)>(
        (c) => (c.state.positionSec, c.state.track?.durationSec ?? 0));
    final c = context.read<PlayerController>();
    final frac = dur > 0 ? (pos / dur).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
            width: 52,
            child: Text(fmtTime(pos),
                style:
                    const TextStyle(fontSize: 16, color: AppColors.textDim))),
        Expanded(
          child: LayoutBuilder(
            builder: (_, box) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              // toque na barra = seek
              onTapUp: dur > 0
                  ? (d) => c.seekTo(d.localPosition.dx / box.maxWidth * dur)
                  : null,
              child: SizedBox(
                height: 36,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: frac.toDouble(),
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceHigh,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
            width: 52,
            child: Text(fmtTime(dur),
                textAlign: TextAlign.right,
                style:
                    const TextStyle(fontSize: 16, color: AppColors.textDim))),
      ],
    );
  }
}
