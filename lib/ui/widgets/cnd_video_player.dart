// lib/ui/widgets/cnd_video_player.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:pip_view/pip_view.dart';
import 'package:video_player/video_player.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  Timer? _retryTicker;
  int _retryAttempts = 0;
  static const int _maxRetries = 3;
  static const int _stallThresholdSec = 4;
  bool _restarting = false;

  double _lastVol = 1.0;
  final List<double> _speeds = const [0.5, 1.0, 1.25, 1.5, 2.0];
  int _speedIx = 1;

  Duration _lastPos = Duration.zero;
  DateTime _lastAdvance = DateTime.now();

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
    _retryTicker?.cancel();
    _disposeCtrl();
    super.dispose();
  }

  Future<void> _open() async {
    _retryAttempts = 0;
    _restarting = false;

    final c = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      httpHeaders: widget.headers ?? const <String, String>{},
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _c = c;

    try {
      await c.initialize();
    } catch (_) {
      _scheduleRetry();
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
        _cancelRetryPipeline();
      }
      if (v.hasError) _scheduleRetry();
      setState(() {});
    });

    _startStallWatch();
    _kickAutoHide();
    setState(() {});
  }

  void _disposeCtrl() {
    final c = _c;
    _c = null;
    c?.dispose();
  }

  void _startStallWatch() {
    _stallT?.cancel();
    _stallT = Timer.periodic(const Duration(seconds: 1), (_) {
      final c = _c;
      if (c == null) return;
      final v = c.value;
      if (!v.isInitialized) return;

      final isVod = v.duration != Duration.zero;
      final nearEnd =
          isVod &&
          (v.duration - v.position) <= const Duration(milliseconds: 700);
      if (nearEnd) return;

      if (v.hasError) {
        _scheduleRetry();
        return;
      }
      if (!v.isPlaying) return;

      final stalledFor = DateTime.now().difference(_lastAdvance);
      if (stalledFor.inSeconds >= _stallThresholdSec) _scheduleRetry();
    });
  }

  void _scheduleRetry() {
    if (!mounted) return;
    if (_restarting) return;

    final c = _c;
    if (c != null && c.value.isPlaying) {
      final stalledFor = DateTime.now().difference(_lastAdvance);
      if (stalledFor.inSeconds < _stallThresholdSec && !c.value.hasError)
        return;
    }

    _restarting = true;
    _retryAttempts = 0;
    _showAttemptSnack();

    _retryTicker?.cancel();
    _retryTicker = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) {
        t.cancel();
        _retryTicker = null;
        return;
      }

      final conn = await Connectivity().checkConnectivity();
      if (conn == ConnectivityResult.none) return;

      _retryAttempts++;
      _showAttemptSnack();

      await _restartStream();

      final ok = _c != null && _c!.value.isInitialized && !_c!.value.hasError;
      if (ok) {
        _cancelRetryPipeline();
        return;
      }

      if (_retryAttempts >= _maxRetries) {
        t.cancel();
        _retryTicker = null;
        _restarting = false;
        _showFailedSnack();
      }
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
      setState(() {});
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

    _lastPos = c.value.position;
    _lastAdvance = DateTime.now();

    c.addListener(() {
      if (!mounted) return;
      final v = c.value;
      if (v.volume >= 0) _lastVol = v.volume;
      if (v.position > _lastPos) {
        _lastPos = v.position;
        _lastAdvance = DateTime.now();
        _cancelRetryPipeline();
      }
      if (v.hasError) _scheduleRetry();
      setState(() {});
    });

    _startStallWatch();
    _kickAutoHide();
    setState(() {});
  }

  Future<void> _replay() async {
    final v = _c?.value;
    if (v == null) {
      _open();
      return;
    }
    _retryAttempts = 0;
    _restarting = false;
    final isVod = v.duration != Duration.zero;
    await _restartStream(fromStart: isVod);
  }

  void _cancelRetryPipeline() {
    _retryTicker?.cancel();
    _retryTicker = null;
    _restarting = false;
    _retryAttempts = 0;
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  }

  void _showAttemptSnack() {
    final m = ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: Text(
          'Reconnexion… (${_retryAttempts.clamp(1, _maxRetries)}/$_maxRetries)',
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showFailedSnack() {
    final m = ScaffoldMessenger.maybeOf(context);
    if (m == null) return;
    m.hideCurrentSnackBar();
    m.showSnackBar(
      SnackBar(
        content: const Text('Lecture interrompue'),
        action: SnackBarAction(label: 'Réessayer', onPressed: _replay),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 6),
      ),
    );
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
  }

  void _cycleSpeed() async {
    final c = _c;
    if (c == null) return;
    _speedIx = (_speedIx + 1) % _speeds.length;
    await c.setPlaybackSpeed(_speeds[_speedIx]);
    setState(() => _show = true);
    _kickAutoHide();
  }

  Future<void> _copyUrl() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copiée'),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PIPView(
      initialCorner: PIPViewCorner.topRight,
      floatingWidth: 240,
      floatingHeight: 135,
      builder: (pipContext, isFloating) {
        final controller = _c;

        if (controller == null || !controller.value.isInitialized) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        final v = controller.value;
        final dur = v.duration;
        final pos = v.position;
        final live = dur == Duration.zero;

        final double ratio = live
            ? 0.0
            : (dur.inMilliseconds == 0
                  ? 0.0
                  : pos.inMilliseconds / dur.inMilliseconds);

        final buffered = v.buffered.isEmpty
            ? Duration.zero
            : v.buffered.last.end;
        final double bufferRatio =
            (dur == Duration.zero || dur.inMilliseconds == 0)
            ? 0.0
            : buffered.inMilliseconds / dur.inMilliseconds;

        final showGoLive =
            live && DateTime.now().difference(_lastAdvance).inSeconds >= 3;

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
                if (!live) {
                  if (x < w * 0.5) {
                    _seekBy(const Duration(seconds: -10));
                  } else {
                    _seekBy(const Duration(seconds: 10));
                  }
                }
                _show = true;
                _kickAutoHide();
                setState(() {});
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoPlayer(controller),

                  if (v.isBuffering && !_restarting)
                    const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),

                  if (!isFloating)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: AnimatedOpacity(
                        opacity: _show ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Row(
                          children: [
                            _Pill(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.wifi_tethering,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    live
                                        ? 'LIVE'
                                        : '${_fmt(pos)} / ${_fmt(dur)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!live)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _Pill(
                                  child: Text(
                                    '${_speeds[_speedIx]}x',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                  if (_show && !isFloating)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        ignoring: false,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.45),
                                Colors.transparent,
                                Colors.transparent,
                                Colors.black.withOpacity(0.60),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (_show && !isFloating)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                          child: _ControlsBar(
                            isLive: live,
                            isPlaying: v.isPlaying,
                            isFullscreen: widget.isFullscreen,
                            volume: v.volume.clamp(0.0, 1.0),
                            ratio: ratio.clamp(0.0, 1.0),
                            bufferRatio: bufferRatio.clamp(0.0, 1.0),
                            position: pos,
                            duration: dur,
                            showGoLive: showGoLive,
                            onPlayPause: _togglePlay,
                            onBack10: () =>
                                _seekBy(const Duration(seconds: -10)),
                            onFwd10: () => _seekBy(const Duration(seconds: 10)),
                            onGoLive: () => _restartStream(fromStart: false),
                            onReplay: _replay,
                            onMute: _toggleMute,
                            onSpeed: _cycleSpeed,
                            onCopy: _copyUrl,
                            onPip: () => PIPView.of(pipContext)?.presentBelow(
                              _PipBottom(
                                onClose: () =>
                                    PIPView.of(pipContext)?.stopFloating(),
                              ),
                            ),
                            onFullscreen: widget.isFullscreen
                                ? () {
                                    final p =
                                        _c?.value.position ?? Duration.zero;
                                    Navigator.of(context).pop<Duration?>(p);
                                  }
                                : _enterFullscreen,
                            onSeek: (v) {
                              if (live) return;
                              final ms = (dur.inMilliseconds * v).toInt();
                              controller.seekTo(Duration(milliseconds: ms));
                            },
                            onVolume: (vol) {
                              controller.setVolume(vol);
                              if (vol > 0) _lastVol = vol;
                            },
                            fmt: _fmt,
                            speedLabel: '${_speeds[_speedIx]}x',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDebug() {
    final c = _c;
    final v = c?.value;
    final buffered = (v == null || v.buffered.isEmpty)
        ? null
        : v.buffered.last.end.inMilliseconds;

    final data = {
      'url': widget.url,
      'headers': widget.headers ?? const <String, String>{},
      'initialized': v?.isInitialized ?? false,
      'playing': v?.isPlaying ?? false,
      'buffering': v?.isBuffering ?? false,
      'live': (v?.duration ?? Duration.zero) == Duration.zero,
      'positionMs': v?.position.inMilliseconds,
      'durationMs': v?.duration.inMilliseconds,
      'bufferedEndMs': buffered,
      'size': v?.size.toString(),
      'volume': v?.volume,
      'speed': _speeds[_speedIx],
      'aspectRatio': v?.aspectRatio,
      'retrying': _restarting,
      'retryAttempts': _retryAttempts,
      'stallThresholdSec': _stallThresholdSec,
      'lastAdvanceAgoSec': DateTime.now().difference(_lastAdvance).inSeconds,
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, ctrl) => Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: ctrl,
            child: SelectableText(
              const JsonEncoder.withIndent('  ').convert(data),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final Widget child;
  const _Pill({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: child,
      ),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  final bool isLive;
  final bool isPlaying;
  final bool isFullscreen;

  final double volume;

  final double ratio;
  final double bufferRatio;

  final Duration position;
  final Duration duration;

  final bool showGoLive;

  final VoidCallback onPlayPause;
  final VoidCallback onBack10;
  final VoidCallback onFwd10;
  final VoidCallback onGoLive;
  final VoidCallback onReplay;
  final VoidCallback onMute;
  final VoidCallback onSpeed;
  final VoidCallback onCopy;
  final VoidCallback onPip;
  final VoidCallback onFullscreen;

  final void Function(double) onSeek;
  final void Function(double) onVolume;

  final String Function(Duration) fmt;
  final String speedLabel;

  const _ControlsBar({
    required this.isLive,
    required this.isPlaying,
    required this.isFullscreen,
    required this.volume,
    required this.ratio,
    required this.bufferRatio,
    required this.position,
    required this.duration,
    required this.showGoLive,
    required this.onPlayPause,
    required this.onBack10,
    required this.onFwd10,
    required this.onGoLive,
    required this.onReplay,
    required this.onMute,
    required this.onSpeed,
    required this.onCopy,
    required this.onPip,
    required this.onFullscreen,
    required this.onSeek,
    required this.onVolume,
    required this.fmt,
    required this.speedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Material(
      color: Colors.black.withOpacity(0.35),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLive)
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: bufferRatio,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white54,
                      ),
                      backgroundColor: Colors.white24,
                      minHeight: 3,
                    ),
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 7,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 14,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.transparent,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                    ),
                    child: Slider(value: ratio, onChanged: onSeek),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                _IconBtn(
                  icon: isPlaying ? Icons.pause : Icons.play_arrow,
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onTap: onPlayPause,
                ),
                if (!isLive) ...[
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: Icons.replay_10,
                    tooltip: '-10s',
                    onTap: onBack10,
                  ),
                  const SizedBox(width: 4),
                  _IconBtn(
                    icon: Icons.forward_10,
                    tooltip: '+10s',
                    onTap: onFwd10,
                  ),
                ],
                const SizedBox(width: 10),
                if (!isLive)
                  Text(
                    '${fmt(position)} / ${fmt(duration)}',
                    style: t.labelMedium?.copyWith(color: Colors.white),
                  )
                else
                  Row(
                    children: [
                      Text(
                        'LIVE',
                        style: t.labelMedium?.copyWith(color: Colors.white),
                      ),
                      if (showGoLive)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: TextButton(
                            onPressed: onGoLive,
                            child: const Text(
                              'Go Live',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                const Spacer(),
                _IconBtn(
                  icon: Icons.copy,
                  tooltip: 'Copier URL',
                  onTap: onCopy,
                ),
                const SizedBox(width: 2),
                _IconBtn(
                  icon: Icons.picture_in_picture_alt_rounded,
                  tooltip: 'Mini-lecteur',
                  onTap: onPip,
                ),
                const SizedBox(width: 2),
                _IconBtn(
                  icon: Icons.replay,
                  tooltip: 'Rejouer',
                  onTap: onReplay,
                ),
                const SizedBox(width: 2),
                _IconBtn(
                  icon: volume > 0 ? Icons.volume_up : Icons.volume_off,
                  tooltip: volume > 0 ? 'Mute' : 'Unmute',
                  onTap: onMute,
                ),
                SizedBox(
                  width: 86,
                  height: 26,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                    ),
                    child: Slider(
                      value: volume,
                      min: 0.0,
                      max: 1.0,
                      onChanged: onVolume,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                TextButton(
                  onPressed: onSpeed,
                  child: Text(
                    speedLabel,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 4),
                _IconBtn(
                  icon: isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  tooltip: isFullscreen ? 'Exit full screen' : 'Full screen',
                  onTap: onFullscreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: Icon(icon, color: Colors.white),
      iconSize: 22,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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

class _PipBottom extends StatelessWidget {
  final VoidCallback onClose;
  const _PipBottom({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mode mini lecteur'),
        actions: [
          IconButton(
            tooltip: 'Fermer',
            icon: const Icon(Icons.close),
            onPressed: onClose,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.picture_in_picture_alt_rounded,
                  size: 44,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                Text(
                  'Mini lecteur activé',
                  textAlign: TextAlign.center,
                  style: t.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Continuez votre navigation.\nTouchez le mini lecteur pour le fermer.',
                  textAlign: TextAlign.center,
                  style: t.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.82),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onClose,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.12),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Fermer le mini lecteur'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
