import 'package:flutter/material.dart';
import '../widgets/cnd_video_player.dart';
import 'episodePlay.dart';

class PlaylistPlayerPage extends StatefulWidget {
  final String title;
  final List<EpisodePlay> playlist;
  final int startIndex;

  const PlaylistPlayerPage({
    required this.title,
    required this.playlist,
    required this.startIndex,
  });

  @override
  State<PlaylistPlayerPage> createState() => _PlaylistPlayerPageState();
}

class _PlaylistPlayerPageState extends State<PlaylistPlayerPage> {
  late int _ix;

  @override
  void initState() {
    super.initState();
    _ix = widget.startIndex.clamp(0, widget.playlist.length - 1);
  }

  void _next() {
    if (_ix < widget.playlist.length - 1) {
      setState(() => _ix += 1);
    }
  }

  void _prev() {
    if (_ix > 0) {
      setState(() => _ix -= 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = widget.playlist[_ix];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.title} • ${_ix + 1}/${widget.playlist.length}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Précédent',
            onPressed: _ix > 0 ? _prev : null,
            icon: const Icon(Icons.skip_previous),
          ),
          IconButton(
            tooltip: 'Suivant',
            onPressed: _ix < widget.playlist.length - 1 ? _next : null,
            icon: const Icon(Icons.skip_next),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(
                  child: CndVideoPlayer(
                    url: cur.url,
                    headers: cur.headers,
                    autoPlay: true,
                    // si vous avez ajouté onEnded dans CndVideoPlayer, décommentez:
                    // onEnded: _next,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    cur.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: _prev,
                      icon: const Icon(Icons.skip_previous),
                      label: const Text('Précédent'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Suivant'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
