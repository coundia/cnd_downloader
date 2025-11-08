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
      // certains forks exigent un Map non-nullable
      httpHeaders: widget.headers ?? const <String, String>{},
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
        : pos.inMilliseconds /
              dur.inMilliseconds.clamp(1, 1 << 31); // évite div/0 sur web

    final timelineRow = Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 22,
          onPressed: () => c.value.isPlaying ? c.pause() : c.play(),
          icon: Icon(
            c.value.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
          ),
          tooltip: c.value.isPlaying ? 'Pause' : 'Play',
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: ratio.clamp(0.0, 1.0),
              onChanged: (v) {
                final ms = (dur.inMilliseconds * v).toInt();
                c.seekTo(Duration(milliseconds: ms));
              },
              activeColor: Colors.white,
              inactiveColor: Colors.white24,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${_fmt(pos)} / ${_fmt(dur)}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );

    final jumpRow = Row(
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 20,
          onPressed: () => c.seekTo(pos - const Duration(seconds: 10)),
          icon: const Icon(Icons.replay_10, color: Colors.white),
          tooltip: 'Back 10s',
        ),
        const SizedBox(width: 8),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: 20,
          onPressed: () => c.seekTo(pos + const Duration(seconds: 10)),
          icon: const Icon(Icons.forward_10, color: Colors.white),
          tooltip: 'Forward 10s',
        ),
      ],
    );

    // Empêche tout overflow : mise à l’échelle automatique si l’espace est trop petit.
    final controls = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Material(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [timelineRow, jumpRow],
            ),
          ),
        ),
      ),
    );

    final aspect = c.value.aspectRatio == 0 ? (16 / 9) : c.value.aspectRatio;

    // Ne PAS emballer ce widget dans un autre AspectRatio.
    return AspectRatio(
      aspectRatio: aspect,
      child: Stack(
        fit: StackFit.expand,
        children: [
          VideoPlayer(c),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          Positioned(left: 8, right: 8, bottom: 8, child: controls),
        ],
      ),
    );
  }
}
