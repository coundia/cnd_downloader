// cnd_video_player.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CndVideoPlayer extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final bool autoPlay;
  final bool isFullscreen;
  final Duration? startAt;

  const CndVideoPlayer({
    super.key,
    required this.url,
    this.headers,
    this.autoPlay = true,
    this.isFullscreen = false,
    this.startAt,
  });

  @override
  State<CndVideoPlayer> createState() => _CndVideoPlayerState();
}

class _CndVideoPlayerState extends State<CndVideoPlayer> {
  VideoPlayerController? _c;
  bool _show = true;
  Timer? _hideT;
  Timer? _stallT;
  Timer? _retryT;
  double _lastVol = 1.0;
  final List<double> _speeds = const [0.5, 1.0, 1.25, 1.5, 2.0];
  int _speedIx = 1;
  Duration _lastPos = Duration.zero;
  DateTime _lastAdvance = DateTime.now();
  int _retry = 0;
  bool _restarting = false;
  bool _fatalError = false; // NEW: UI state for fatal error

  Duration get currentPosition => _c?.value.position ?? Duration.zero;

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
    _stallT?.cancel();
    _retryT?.cancel();
    _disposeCtrl();
    super.dispose();
  }

  Future<void> _open() async {
    // NEW: Reset all error/retry state on new open
    _retry = 0;
    _restarting = false;
    _fatalError = false;
    if (mounted) setState(() {});

    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.headers ?? const <String, String>{},
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _c = c;
    try {
      await c.initialize();
    } catch (_) {
      _scheduleRetry(); // MODIFIED: Don't increment retry here
      return;
    }
    if (!mounted) return;
    if ((widget.startAt ?? Duration.zero) > Duration.zero &&
        c.value.duration != Duration.zero) {
      await c.seekTo(widget.startAt!);
    }
    _lastVol = _lastVol <= 0 ? 1.0 : _lastVol;
    await c.setVolume(_lastVol);
    await c.setPlaybackSpeed(_speeds[_speedIx]);
    if (widget.autoPlay) await c.play();
    _lastPos = c.value.position;
    _lastAdvance = DateTime.now();
    c.addListener(() {
      if (!mounted) return;
      final v = c.value;
      if (v.volume >= 0) _lastVol = v.volume;
      if (v.position > _lastPos) {
        _lastPos = v.position;
        _lastAdvance = DateTime.now();
      }
      if (v.hasError) {
        // MODIFIED: Only schedule retry if not already restarting
        if (!_restarting) _scheduleRetry();
      }
      setState(() {});
    });
    _startStallWatch();
    _kickAutoHide();
    setState(() {});
  }

  void _disposeCtrl() {
    final c = _c;
    _c = null;
    c?.removeListener(() {});
    c?.dispose();
  }

  void _startStallWatch() {
    _stallT?.cancel();
    _stallT = Timer.periodic(const Duration(seconds: 1), (_) {
      final c = _c;
      if (c == null) return;
      final v = c.value;
      final isLive = v.duration == Duration.zero;
      if (!isLive) return;
      if (!v.isInitialized) return;
      if (v.hasError) {
        // MODIFIED
        if (!_restarting) _scheduleRetry();
        return;
      }
      if (!v.isPlaying) return;
      final stalledFor = DateTime.now().difference(_lastAdvance);
      if (stalledFor.inSeconds >= 6) {
        // MODIFIED
        if (!_restarting) _scheduleRetry();
      }
    });
  }

  void _scheduleRetry() {
    if (!mounted) return;
    if (_restarting) return;

    // NEW: Increment retry count *when scheduling*
    _retry++;

    // NEW: Check retry limit
    if (_retry > 3) {
      setState(() {
        _fatalError = true;
        _restarting = false;
      });
      _disposeCtrl(); // Stop the player
      return;
    }

    _restarting = true;
    _retryT?.cancel();
    // Use exponential backoff: 1s, 2s, 4s
    final backoffSeconds = 1 << (_retry - 1);
    _retryT = Timer(Duration(seconds: backoffSeconds), () async {
      if (!mounted) return;
      await _restartStream();
    });
    setState(() {});
  }

  Future<void> _restartStream({bool fromStart = false}) async {
    final old = _c;
    if (old == null) return;
    final wasPlaying = old.value.isPlaying;
    final isLive = old.value.duration == Duration.zero;
    final resume = fromStart ? Duration.zero : old.value.position;
    final spd = _speeds[_speedIx];
    final vol = old.value.volume;
    _stallT?.cancel();
    _hideT?.cancel();
    try {
      await old.pause();
    } catch (_) {}
    _disposeCtrl();

    final base = Uri.parse(widget.url);
    final qp = Map<String, String>.from(base.queryParameters);
    qp['r'] = DateTime.now().millisecondsSinceEpoch.toString();
    final uri = base.replace(queryParameters: qp);

    final c = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: widget.headers ?? const <String, String>{},
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _c = c;
    try {
      await c.initialize();
    } catch (_) {
      // MODIFIED: Just schedule next retry, don't increment here
      _restarting = false;
      _scheduleRetry();
      return;
    }
    if (!mounted) return;
    if (!isLive && resume > Duration.zero) {
      try {
        await c.seekTo(resume);
      } catch (_) {}
    }
    await c.setPlaybackSpeed(spd);
    await c.setVolume(vol <= 0 ? _lastVol : vol);
    if (wasPlaying || widget.autoPlay) {
      try {
        await c.play();
      } catch (_) {}
    }
    _retry = 0; // NEW: Reset retry count on SUCCESS
    _restarting = false;
    _lastPos = c.value.position;
    _lastAdvance = DateTime.now();
    c.addListener(() {
      if (!mounted) return;
      final v = c.value;
      if (v.volume >= 0) _lastVol = v.volume;
      if (v.position > _lastPos) {
        _lastPos = v.position;
        _lastAdvance = DateTime.now();
      }
      if (v.hasError) {
        if (!_restarting) _scheduleRetry();
      }
      setState(() {});
    });
    _startStallWatch();
    _kickAutoHide();
    setState(() {});
  }

  Future<void> _replay() async {
    final v = _c?.value;
    if (v == null) return;

    // NEW: Reset error state on manual replay
    _retry = 0;
    _restarting = false;
    _fatalError = false;
    if (mounted) setState(() {}); // Update UI to remove error

    final isVod = v.duration != Duration.zero;
    await _restartStream(fromStart: isVod);
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
    final wasPlaying = c.value.isPlaying;
    final pos = c.value.position;
    _hideT?.cancel();
    await c.pause();
    final key = GlobalKey<_CndVideoPlayerState>();
    final returnedPos = await Navigator.of(context).push<Duration?>(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) => _FullscreenVideo(
          playerKey: key,
          url: widget.url,
          headers: widget.headers,
          startAt: pos,
          autoPlay: wasPlaying,
        ),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ),
    );
    if (!mounted) return;
    final resumeAt = returnedPos ?? pos;
    await c.seekTo(resumeAt);
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
    // NEW: Handle fatal error state
    if (_fatalError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Impossible de lire la vidéo.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'La connexion a échoué après 3 tentatives.',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.replay),
                label: const Text('Réessayer'),
                onPressed: _replay, // Use the replay function to retry
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white24,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final c = _c;
    if (c == null || !c.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(color: Colors.white),
        ),
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
                    iconSize: 22,
                    onPressed: _replay,
                    icon: const Icon(Icons.replay, color: Colors.white),
                    tooltip: 'Rejouer',
                  ),
                  const SizedBox(width: 4),
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
                        ? () {
                            final p = _c?.value.position ?? Duration.zero;
                            Navigator.of(context).pop<Duration?>(p);
                          }
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
      child: Container(
        color: Colors.black,
        child: GestureDetector(
          onTap: _toggleControls,
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

              // NEW: Separate UI for buffering vs restarting
              if (v.isBuffering && !_restarting)
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
              // NEW: UI for restarting
              if (_restarting)
                Container(
                  color: Colors.black54,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.white),
                      const SizedBox(height: 16),
                      Text(
                        'Connexion perdue. Tentative $_retry/3...',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
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
      ),
    );
  }
}

class _FullscreenVideo extends StatefulWidget {
  final GlobalKey<_CndVideoPlayerState> playerKey;
  final String url;
  final Map<String, String>? headers;
  final Duration startAt;
  final bool autoPlay;

  const _FullscreenVideo({
    required this.playerKey,
    required this.url,
    required this.headers,
    required this.startAt,
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
    return WillPopScope(
      onWillPop: () async {
        final pos =
            widget.playerKey.currentState?.currentPosition ?? Duration.zero;
        Navigator.of(context).pop<Duration?>(pos);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          left: false,
          right: false,
          top: false,
          bottom: false,
          child: Center(
            child: CndVideoPlayer(
              key: widget.playerKey,
              url: widget.url,
              headers: widget.headers,
              autoPlay: widget.autoPlay,
              isFullscreen: true,
              startAt: widget.startAt,
            ),
          ),
        ),
      ),
    );
  }
}
