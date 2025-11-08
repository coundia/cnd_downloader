import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class CndVideoPlayer extends StatefulWidget {
  final String url;
  final Map<String, String>? headers;
  final bool autoPlay;
  final double aspectRatio;

  const CndVideoPlayer({
    super.key,
    required this.url,
    this.headers,
    this.autoPlay = true,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<CndVideoPlayer> createState() => _CndVideoPlayerState();
}

class _CndVideoPlayerState extends State<CndVideoPlayer> {
  late final Player _player;
  late final VideoController _controller;

  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;
  bool _playing = false;
  bool _muted = false;
  bool _buffering = false;
  double _volume = 100.0;
  StreamSubscription? _subPos;
  StreamSubscription? _subDur;
  StreamSubscription? _subPlaying;
  StreamSubscription? _subBuf;
  StreamSubscription? _subVol;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _bind();
    _open(widget.url, widget.headers, play: widget.autoPlay);
  }

  @override
  void didUpdateWidget(covariant CndVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.headers != widget.headers) {
      _open(widget.url, widget.headers, play: _playing);
    }
  }

  @override
  void dispose() {
    _subPos?.cancel();
    _subDur?.cancel();
    _subPlaying?.cancel();
    _subBuf?.cancel();
    _subVol?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _open(
    String url,
    Map<String, String>? headers, {
    bool play = true,
  }) async {
    await _player.open(
      Media(url, httpHeaders: headers ?? const {}),
      play: play,
    );
  }

  void _bind() {
    _subPos = _player.stream.position.listen((e) {
      if (!mounted) return;
      setState(() => _pos = e);
    });
    _subDur = _player.stream.duration.listen((e) {
      if (!mounted) return;
      setState(() => _dur = e);
    });
    _subPlaying = _player.stream.playing.listen((e) {
      if (!mounted) return;
      setState(() => _playing = e);
    });
    _subBuf = _player.stream.buffering.listen((e) {
      if (!mounted) return;
      setState(() => _buffering = e);
    });
    _subVol = _player.stream.volume.listen((e) {
      if (!mounted) return;
      setState(() {
        _volume = e.clamp(0, 100).toDouble();
        _muted = _volume == 0;
      });
    });
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _seekRelative(Duration delta) {
    final t = _pos + delta;
    final clamped = t < Duration.zero ? Duration.zero : (t > _dur ? _dur : t);
    _player.seek(clamped);
  }

  void _togglePlay() {
    _playing ? _player.pause() : _player.play();
  }

  void _toggleMute() {
    if (_muted) {
      _player.setVolume(_volume == 0 ? 50 : _volume);
    } else {
      _player.setVolume(0);
    }
  }

  Future<void> _enterFullscreen() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: AspectRatio(
                      aspectRatio: widget.aspectRatio,
                      child: Video(controller: _controller, controls: null),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      color: Colors.white,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sliderValue = _dur.inMilliseconds == 0
        ? 0.0
        : _pos.inMilliseconds.clamp(0, _dur.inMilliseconds) /
              _dur.inMilliseconds;

    final controls = LayoutBuilder(
      builder: (c, bc) {
        final narrow = bc.maxWidth < 520;
        final playBtn = IconButton(
          onPressed: _togglePlay,
          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
          tooltip: _playing ? 'Pause' : 'Play',
        );
        final backBtn = IconButton(
          onPressed: () => _seekRelative(const Duration(seconds: -10)),
          icon: const Icon(Icons.replay_10),
          tooltip: 'Back 10s',
        );
        final fwdBtn = IconButton(
          onPressed: () => _seekRelative(const Duration(seconds: 10)),
          icon: const Icon(Icons.forward_10),
          tooltip: 'Forward 10s',
        );
        final muteBtn = IconButton(
          onPressed: _toggleMute,
          icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
          tooltip: _muted ? 'Unmute' : 'Mute',
        );
        final vol = SizedBox(
          width: narrow ? 100 : 140,
          child: Slider(
            value: _volume,
            min: 0,
            max: 100,
            onChanged: (v) => _player.setVolume(v),
          ),
        );
        final fsBtn = IconButton(
          onPressed: _enterFullscreen,
          icon: const Icon(Icons.fullscreen),
          tooltip: 'Fullscreen',
        );

        final time = Text(
          '${_fmt(_pos)} / ${_fmt(_dur)}',
          style: Theme.of(context).textTheme.labelSmall,
        );

        final row1 = Row(
          children: [
            playBtn,
            backBtn,
            fwdBtn,
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: sliderValue,
                onChanged: (v) {
                  final ms = (_dur.inMilliseconds * v).toInt();
                  _player.seek(Duration(milliseconds: ms));
                },
              ),
            ),
            const SizedBox(width: 8),
            time,
          ],
        );

        final row2 = Row(
          children: [
            muteBtn,
            vol,
            const Spacer(),
            if (_buffering)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            fsBtn,
          ],
        );

        if (narrow) {
          return Column(children: [row1, row2]);
        }
        return Row(
          children: [
            Expanded(child: row1),
            const SizedBox(width: 12),
            row2,
          ],
        );
      },
    );

    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Video(controller: _controller, controls: null),
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
        Material(
          color: cs.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: controls,
          ),
        ),
      ],
    );
  }
}
