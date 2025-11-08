import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CndVideoPlayer extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final bool autoPlay;

  const CndVideoPlayer({
    super.key,
    required this.url,
    this.headers,
    this.autoPlay = true,
  });

  @override
  State<CndVideoPlayer> createState() => _CndVideoPlayerState();
}

class _CndVideoPlayerState extends State<CndVideoPlayer> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(covariant CndVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.headers != widget.headers) {
      _disposeCtrl();
      _open();
    }
  }

  @override
  void dispose() {
    _disposeCtrl();
    super.dispose();
  }

  Future<void> _open() async {
    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      // httpHeaders: widget.headers,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _c = c;
    await c.initialize();
    if (!mounted) return;
    if (widget.autoPlay) await c.play();
    setState(() {});
  }

  void _disposeCtrl() {
    final c = _c;
    _c = null;
    c?.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || !c.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final dur = c.value.duration;
    final pos = c.value.position;
    final ratio = dur.inMilliseconds == 0
        ? 0.0
        : pos.inMilliseconds / dur.inMilliseconds.clamp(1, 1 << 31);

    final row1 = Row(
      children: [
        IconButton(
          onPressed: () => c.value.isPlaying ? c.pause() : c.play(),
          icon: Icon(c.value.isPlaying ? Icons.pause : Icons.play_arrow),
        ),
        IconButton(
          onPressed: () => c.seekTo(pos - const Duration(seconds: 10)),
          icon: const Icon(Icons.replay_10),
        ),
        IconButton(
          onPressed: () => c.seekTo(pos + const Duration(seconds: 10)),
          icon: const Icon(Icons.forward_10),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            value: ratio.clamp(0.0, 1.0),
            onChanged: (v) {
              final ms = (dur.inMilliseconds * v).toInt();
              c.seekTo(Duration(milliseconds: ms));
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_fmt(pos)} / ${_fmt(dur)}',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );

    return Column(
      children: [
        AspectRatio(
          aspectRatio: c.value.aspectRatio == 0
              ? (16 / 9)
              : c.value.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(c),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LIVE',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: row1,
        ),
      ],
    );
  }
}
