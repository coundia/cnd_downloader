import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  @override
  void initState() {
    super.initState();
    _omdbFuture = _fetchOmdb(widget.item.name);
  }

  Map<String, String> _headers() {
    final h = <String, String>{};
    final ua = (settings.defaultUserAgent).trim();
    if (ua.isNotEmpty) h['user-agent'] = ua;
    final ref = (settings.defaultReferer ?? '').trim();
    if (ref.isNotEmpty) h['referer'] = ref;
    return h;
  }

  Future<_OmdbData?> _fetchOmdb(String rawTitle) async {
    final key = settings.omdbApiKey?.trim();
    if (key == null || key.isEmpty) return null;
    final cleaned = rawTitle
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\([^\)]*\)'), '')
        .replaceAll(RegExp(r'\{[^\}]*\}'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final uri = Uri.https('www.omdbapi.com', '/', {
      't': cleaned,
      'apikey': key,
      'plot': 'short',
    });
    try {
      final resp = await Dio().getUri(uri);
      if (resp.statusCode == 200 && resp.data is Map) {
        final m = Map<String, dynamic>.from(resp.data as Map);
        if ((m['Response'] as String?)?.toLowerCase() == 'true') {
          return _OmdbData.fromJson(m);
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _PosterImage(url: widget.item.logo),
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
                return keyMissing
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.dividerColor),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OMDb indisponible. Renseigner OMDb API Key dans Settings.',
                        ),
                      )
                    : const SizedBox.shrink();
              }
              return _OmdbCard(data: d);
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

  _OmdbData({
    required this.title,
    required this.year,
    required this.runtime,
    required this.genre,
    required this.plot,
    required this.imdbID,
    required this.rating10,
    required this.votes,
  });

  factory _OmdbData.fromJson(Map<String, dynamic> m) {
    final r = double.tryParse((m['imdbRating'] ?? '').toString()) ?? 0.0;
    return _OmdbData(
      title: (m['Title'] ?? '').toString(),
      year: (m['Year'] ?? '').toString(),
      runtime: (m['Runtime'] ?? '').toString(),
      genre: (m['Genre'] ?? '').toString(),
      plot: (m['Plot'] ?? '').toString(),
      imdbID: (m['imdbID'] ?? '').toString(),
      rating10: r,
      votes: (m['imdbVotes'] ?? '').toString(),
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
