import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../../../data/iptv_models.dart';
import '../../../../core/settings.dart';
import '../../../../core/paths.dart';
import '../../../../viewmodels/download_list_vm.dart';
import '../../widgets/cnd_video_player.dart';

class MovieDetailsPage extends ConsumerStatefulWidget {
  final IptvItem item;
  const MovieDetailsPage({super.key, required this.item});

  @override
  ConsumerState<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends ConsumerState<MovieDetailsPage> {
  late final Future<_OmdbData?> _omdbFuture;

  String? _dbgStep;
  String? _dbgUrl;
  int? _dbgStatus;
  String? _dbgBody;
  String? _dbgError;
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();
    _omdbFuture = _fetchAndPersist(widget.item);
  }

  Future<_OmdbData?> _fetchAndPersist(IptvItem item) async {
    final d = await _fetchOmdb(item.name);
    if (d != null) {
      await _persistOmdbToDb(item.id, d);
    }
    return d;
  }

  Future<void> _persistOmdbToDb(int itemId, _OmdbData d) async {
    final isar = Isar.getInstance();
    if (isar == null) return;
    await isar.writeTxn(() async {
      final cur = await isar.iptvItems.get(itemId);
      if (cur == null) return;
      if (d.imdbID.isNotEmpty) cur.imdbId = d.imdbID;
      if (d.rating10 > 0) cur.imdbRating = d.rating10;
      if (d.plot.isNotEmpty) cur.imdbDescription = d.plot;
      cur.updatedAt = DateTime.now();
      await isar.iptvItems.put(cur);
    });
  }

  Map<String, String> _headers() {
    final h = <String, String>{};
    final ua = (settings.defaultUserAgent).trim();
    if (ua.isNotEmpty) h['user-agent'] = ua;
    final ref = (settings.defaultReferer ?? '').trim();
    if (ref.isNotEmpty) h['referer'] = ref;
    return h;
  }

  Dio _dio() {
    final d = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: settings.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: settings.receiveTimeoutMs),
        headers: {'user-agent': settings.defaultUserAgent},
        responseType: ResponseType.json,
      ),
    );
    d.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (o) => debugPrint('[OMDb] $o'),
      ),
    );
    return d;
  }

  _TitleYear _explodeTitleYear(String raw) {
    var s = raw.replaceAll(RegExp(r'\[[^\]]*\]|\([^\)]*\)|\{[^\}]*\}'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    final seps = RegExp(r'\s*[-|·•–—]\s*');
    final tokens = s
        .split(seps)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    String? year;
    if (tokens.isNotEmpty && RegExp(r'^(19|20)\d{2}$').hasMatch(tokens.last)) {
      year = tokens.removeLast();
    }
    const blacklist = <String>{
      'FR',
      'VF',
      'VOSTFR',
      'TRUEFRENCH',
      'FRENCH',
      'MULTI',
      'MULTILANG',
      'EN',
      'ENG',
      'VO',
      'SUBFRENCH',
      'HD',
      '1080P',
      '720P',
      '4K',
      'HDR',
      'WEBDL',
      'WEB-DL',
    };
    final core = tokens
        .where((t) => !blacklist.contains(t.toUpperCase()))
        .toList();
    final title = (core.isEmpty ? tokens : core).join(' ').trim();
    return _TitleYear(title, year);
  }

  Future<_OmdbData?> _fetchOmdb(String rawTitle) async {
    final key = settings.omdbApiKey?.trim();
    if (key == null || key.isEmpty) return null;
    final dio = _dio();
    final ty = _explodeTitleYear(rawTitle);
    try {
      _dbgStep = 'by title+year';
      final uri = Uri.https('www.omdbapi.com', '/', {
        't': ty.title,
        if (ty.year != null) 'y': ty.year!,
        'type': 'movie',
        'plot': 'full',
        'r': 'json',
        'apikey': key,
      });
      setState(() {
        _dbgUrl = uri.toString();
        _dbgStatus = null;
        _dbgBody = null;
        _dbgError = null;
      });
      final r = await dio.getUri(uri);
      setState(() {
        _dbgStatus = r.statusCode;
        final s = r.data.toString();
        _dbgBody = s.length > 2000 ? '${s.substring(0, 2000)}…' : s;
      });
      if (r.statusCode == 200 && r.data is Map) {
        final m = Map<String, dynamic>.from(r.data as Map);
        if ((m['Response']?.toString().toLowerCase() ?? '') == 'true') {
          return _OmdbData.fromJson(m);
        }
      }
    } catch (e) {
      setState(() => _dbgError = e.toString());
    }
    return null;
  }

  Future<String?> imdbFromTitle(String rawTitle) async {
    final key = settings.omdbApiKey?.trim();
    if (key == null || key.isEmpty) return null;
    final dio = _dio();
    final ty = _explodeTitleYear(rawTitle);
    try {
      final uri = Uri.https('www.omdbapi.com', '/', {
        't': ty.title,
        if (ty.year != null) 'y': ty.year!,
        'type': 'movie',
        'r': 'json',
        'apikey': key,
      });
      final r = await dio.getUri(uri);
      if (r.statusCode == 200 && r.data is Map) {
        final m = Map<String, dynamic>.from(r.data as Map);
        if ((m['Response']?.toString().toLowerCase() ?? '') == 'true') {
          final id = (m['imdbID'] ?? '').toString();
          return id.isEmpty ? null : id;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final host = _safeHost(widget.item.streamUrl);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Debug',
            onPressed: () => setState(() => _showDebug = !_showDebug),
            icon: const Icon(Icons.bug_report),
          ),
          IconButton(
            tooltip: 'Copy URL',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: widget.item.streamUrl),
              );
              if (!mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('URL copied')));
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          FutureBuilder<_OmdbData?>(
            future: _omdbFuture,
            builder: (context, snap) {
              final d = snap.data;
              final poster = d?.posterUrl?.isNotEmpty == true
                  ? d!.posterUrl
                  : widget.item.logo;
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _PosterImage(url: poster),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.transparent, Colors.black26],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          onPressed: () {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MoviePlayerPage(
                                    title: widget.item.name,
                                    url: widget.item.streamUrl,
                                    headers: _headers(),
                                  ),
                                ),
                              );
                            });
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: widget.item.groupTitle ?? 'Movie'),
              _Chip(text: host),
            ],
          ),
          const SizedBox(height: 12),
          FutureBuilder<_OmdbData?>(
            future: _omdbFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const _OmdbSkeleton();
              }
              final d = snap.data;
              if (d == null) {
                final keyMissing =
                    (settings.omdbApiKey == null ||
                    settings.omdbApiKey!.trim().isEmpty);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (keyMissing)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OMDb unavailable. Set OMDb API Key in Settings.',
                        ),
                      ),
                    if (_showDebug)
                      _DebugBlock(
                        step: _dbgStep,
                        url: _dbgUrl,
                        status: _dbgStatus,
                        body: _dbgBody,
                        error: _dbgError,
                      ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OmdbCard(data: d),
                  if (_showDebug)
                    _DebugBlock(
                      step: _dbgStep,
                      url: _dbgUrl,
                      status: _dbgStatus,
                      body: _dbgBody,
                      error: _dbgError,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                widget.item.streamUrl,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (c, bc) {
              final narrow = bc.maxWidth < 420;
              final watchBtn = Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MoviePlayerPage(
                            title: widget.item.name,
                            url: widget.item.streamUrl,
                            headers: _headers(),
                          ),
                        ),
                      );
                    });
                  },
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Watch'),
                ),
              );
              final downloadBtn = Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final dir = await defaultDownloadDir();
                    await ref
                        .read(listVmProvider.notifier)
                        .addOnly(widget.item.streamUrl, dir);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Queued to Downloads')),
                    );
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                ),
              );
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [watchBtn, const SizedBox(height: 10), downloadBtn],
                );
              }
              return Row(
                children: [watchBtn, const SizedBox(width: 10), downloadBtn],
              );
            },
          ),
        ],
      ),
    );
  }

  String _safeHost(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return 'unknown';
    }
  }
}

class _PosterImage extends StatelessWidget {
  final String? url;
  const _PosterImage({required this.url});

  @override
  Widget build(BuildContext context) {
    if ((url ?? '').isEmpty) {
      return const ColoredBox(color: Color(0xFF111111));
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFF111111)),
      loadingBuilder: (c, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class MoviePlayerPage extends StatelessWidget {
  final String title;
  final String url;
  final Map<String, String> headers;
  const MoviePlayerPage({
    super.key,
    required this.title,
    required this.url,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CndVideoPlayer(url: url, headers: headers, autoPlay: true),
          ),
        ),
      ),
    );
  }
}

class _OmdbData {
  final String title;
  final String year;
  final String runtime;
  final String genre;
  final String plot;
  final String imdbID;
  final double rating10;
  final String votes;
  final String? posterUrl;

  _OmdbData({
    required this.title,
    required this.year,
    required this.runtime,
    required this.genre,
    required this.plot,
    required this.imdbID,
    required this.rating10,
    required this.votes,
    required this.posterUrl,
  });

  factory _OmdbData.fromJson(Map<String, dynamic> m) {
    final r = double.tryParse((m['imdbRating'] ?? '').toString()) ?? 0.0;
    final poster = (m['Poster'] ?? '').toString();
    return _OmdbData(
      title: (m['Title'] ?? '').toString(),
      year: (m['Year'] ?? '').toString(),
      runtime: (m['Runtime'] ?? '').toString(),
      genre: (m['Genre'] ?? '').toString(),
      plot: (m['Plot'] ?? '').toString(),
      imdbID: (m['imdbID'] ?? '').toString(),
      rating10: r,
      votes: (m['imdbVotes'] ?? '').toString(),
      posterUrl: poster.isEmpty || poster == 'N/A' ? null : poster,
    );
  }
}

class _OmdbCard extends StatelessWidget {
  final _OmdbData data;
  const _OmdbCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating5 = (data.rating10 / 2.0).clamp(0.0, 5.0);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${data.title} • ${data.year} • ${data.runtime} • ${data.genre}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _Stars(rating: rating5),
              const SizedBox(width: 8),
              Text('${data.rating10.toStringAsFixed(1)}/10'),
              const SizedBox(width: 6),
              Text('(${data.votes})', style: theme.textTheme.bodySmall),
              const Spacer(),
              if (data.imdbID.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    final url = Uri.parse(
                      'https://www.imdb.com/title/${data.imdbID}/',
                    );
                    Clipboard.setData(ClipboardData(text: url.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('IMDB URL copied')),
                    );
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('IMDb'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(data.plot, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final icons = <Icon>[];
    for (var i = 1; i <= 5; i++) {
      final v = rating - i + 1;
      if (v >= 1) {
        icons.add(const Icon(Icons.star, size: 18));
      } else if (v >= 0.5) {
        icons.add(const Icon(Icons.star_half, size: 18));
      } else {
        icons.add(const Icon(Icons.star_border, size: 18));
      }
    }
    return Row(children: icons);
  }
}

class _OmdbSkeleton extends StatelessWidget {
  const _OmdbSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _DebugBlock extends StatelessWidget {
  final String? step;
  final String? url;
  final int? status;
  final String? body;
  final String? error;
  const _DebugBlock({this.step, this.url, this.status, this.body, this.error});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mono = t.bodySmall?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: mono ?? const TextStyle(fontSize: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OMDb request (${step ?? 'n/a'})'),
            if (url != null) Text('URL: $url'),
            if (status != null) Text('Status: $status'),
            if (error != null) Text('Error: $error'),
            if (body != null) Text('Body: $body'),
          ],
        ),
      ),
    );
  }
}

class _TitleYear {
  final String title;
  final String? year;
  const _TitleYear(this.title, this.year);
}
