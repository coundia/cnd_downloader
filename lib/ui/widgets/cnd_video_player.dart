import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CndVideoPlayer extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final bool autoPlay;
  final bool isFullscreen;

  const CndVideoPlayer({
    super.key,
    required this.url,
    this.headers,
    this.autoPlay = true,
    this.isFullscreen = false,
  });

  @override
  State<CndVideoPlayer> createState() => _CndVideoPlayerState();
}

class _CndVideoPlayerState extends State<CndVideoPlayer> {
  VideoPlayerController? _c;
  bool _show = true;
  Timer? _hideT;
  double _lastVol = 1.0;
  final List<double> _speeds = const [0.5, 1.0, 1.25, 1.5, 2.0];
  int _speedIx = 1;

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
    _hideT?.cancel();
    _disposeCtrl();
    super.dispose();
  }

  Future<void> _open() async {
    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.headers ?? const <String, String>{},
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _c = c;
    await c.initialize();
    if (!mounted) return;
    await c.setVolume(_lastVol);
    await c.setPlaybackSpeed(_speeds[_speedIx]);
    if (widget.autoPlay) await c.play();
    c.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _kickAutoHide();
    setState(() {});
  }

  void _disposeCtrl() {
    final c = _c;
    _c = null;
    c?.dispose();
  }

  void _toggleControls() {
    setState(() => _show = !_show);
    if (_show) _kickAutoHide();
  }

  void _kickAutoHide() {
    _hideT?.cancel();
    if (_c?.value.isPlaying == true) {
      _hideT = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _show = false);
      });
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _enterFullscreen() async {
    final c = _c;
    if (c == null) return;

    // État courant
    final wasPlaying = c.value.isPlaying;
    final pos = c.value.position;
    final curVol = c.value.volume;
    final curSpeed = _speeds[_speedIx];

    // Stopper le flux courant avant d’ouvrir le plein écran
    _hideT?.cancel();
    await c.pause();

    // Ouvrir le plein écran avec reprise à la même position
    final returnedPos = await Navigator.of(context).push<Duration?>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenVideo(
          url: widget.url,
          headers: widget.headers,
          startAt: pos,
          speed: curSpeed,
          volume: curVol,
          autoPlay: wasPlaying,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );

    if (!mounted) return;

    // Revenir à la position rendue par le plein écran
    if (returnedPos != null) {
      await c.seekTo(returnedPos);
    }

    // Rejouer si la vidéo jouait avant le plein écran
    if (wasPlaying) {
      await c.play();
      _show = true;
      _kickAutoHide();
    } else {
      setState(() => _show = true);
    }
  }

  void _togglePlay() async {
    final c = _c;
    if (c == null) return;
    if (c.value.isPlaying) {
      await c.pause();
      setState(() => _show = true);
      _hideT?.cancel();
    } else {
      await c.play();
      _kickAutoHide();
    }
  }

  void _seekBy(Duration delta) {
    final c = _c;
    if (c == null) return;
    final d = c.value.duration;
    if (d == Duration.zero) return;
    final p = c.value.position + delta;
    final clamped = p < Duration.zero ? Duration.zero : (p > d ? d : p);
    c.seekTo(clamped);
  }

  void _toggleMute() async {
    final c = _c;
    if (c == null) return;
    if (c.value.volume > 0) {
      _lastVol = c.value.volume;
      await c.setVolume(0);
    } else {
      await c.setVolume(_lastVol <= 0 ? 1.0 : _lastVol);
    }
    setState(() {});
  }

  void _cycleSpeed() async {
    final c = _c;
    if (c == null) return;
    _speedIx = (_speedIx + 1) % _speeds.length;
    await c.setPlaybackSpeed(_speeds[_speedIx]);
    setState(() {});
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

    final v = c.value;
    final dur = v.duration;
    final pos = v.position;
    final live = dur == Duration.zero;
    final ratio = live
        ? 0.0
        : (dur.inMilliseconds == 0
              ? 0.0
              : pos.inMilliseconds / dur.inMilliseconds.clamp(1, 1 << 31));

    final controls = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!live)
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2.5,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
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
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 24,
                    onPressed: _togglePlay,
                    icon: Icon(
                      v.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    tooltip: v.isPlaying ? 'Pause' : 'Play',
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                    onPressed: () => _seekBy(const Duration(seconds: -10)),
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    tooltip: '-10s',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                    onPressed: () => _seekBy(const Duration(seconds: 10)),
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    tooltip: '+10s',
                  ),
                  const SizedBox(width: 10),
                  if (!live)
                    Text(
                      '${_fmt(pos)} / ${_fmt(dur)}  •  -${_fmt(dur - pos)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    )
                  else
                    const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                    onPressed: _toggleMute,
                    icon: Icon(
                      v.volume > 0 ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                    ),
                    tooltip: v.volume > 0 ? 'Mute' : 'Unmute',
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    onPressed: _cycleSpeed,
                    child: Text(
                      '${_speeds[_speedIx]}x',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 22,
                    onPressed: widget.isFullscreen
                        ? Navigator.of(context).maybePop
                        : _enterFullscreen,
                    icon: Icon(
                      widget.isFullscreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      color: Colors.white,
                    ),
                    tooltip: widget.isFullscreen
                        ? 'Exit full screen'
                        : 'Full screen',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final aspect = v.aspectRatio == 0 ? (16 / 9) : v.aspectRatio;

    return AspectRatio(
      aspectRatio: aspect,
      child: GestureDetector(
        onTap: () {
          _toggleControls();
        },
        onDoubleTapDown: (d) {
          final w = MediaQuery.of(context).size.width;
          final x = d.globalPosition.dx;
          if (x < w * 0.5) {
            _seekBy(const Duration(seconds: -10));
          } else {
            _seekBy(const Duration(seconds: 10));
          }
          _show = true;
          _kickAutoHide();
          setState(() {});
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            VideoPlayer(c),
            if (v.isBuffering)
              const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
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
                  live ? 'LIVE' : 'VOD',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white),
                ),
              ),
            ),
            if (_show)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Material(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(8),
                  child: controls,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenVideo extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final Duration startAt;
  final double speed;
  final double volume;
  final bool autoPlay;

  const _FullscreenVideo({
    required this.url,
    required this.headers,
    required this.startAt,
    required this.speed,
    required this.volume,
    required this.autoPlay,
  });

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        left: false,
        right: false,
        top: false,
        bottom: false,
        child: Center(
          child: _FullscreenPlayerBody(
            url: widget.url,
            headers: widget.headers,
            startAt: widget.startAt,
            speed: widget.speed,
            volume: widget.volume,
            autoPlay: widget.autoPlay,
          ),
        ),
      ),
    );
  }
}

class _FullscreenPlayerBody extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final Duration startAt;
  final double speed;
  final double volume;
  final bool autoPlay;

  const _FullscreenPlayerBody({
    required this.url,
    required this.headers,
    required this.startAt,
    required this.speed,
    required this.volume,
    required this.autoPlay,
  });

  @override
  State<_FullscreenPlayerBody> createState() => _FullscreenPlayerBodyState();
}

class _FullscreenPlayerBodyState extends State<_FullscreenPlayerBody> {
  VideoPlayerController? _c;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    final pos = _c?.value.position ?? Duration.zero;
    Navigator.of(context).pop<Duration?>(pos);
    _c?.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.headers ?? const <String, String>{},
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _c = c;
    await c.initialize();
    await c.setPlaybackSpeed(widget.speed);
    await c.setVolume(widget.volume);
    if (widget.startAt > Duration.zero) {
      await c.seekTo(widget.startAt);
    }
    if (widget.autoPlay) await c.play();
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;
    if (c == null || !c.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    final ar = c.value.aspectRatio == 0 ? (16 / 9) : c.value.aspectRatio;
    return AspectRatio(
      aspectRatio: ar,
      child: CndVideoPlayer(
        url: widget.url,
        headers: widget.headers,
        autoPlay: true,
        isFullscreen: true,
      ),
    );
  }
}
