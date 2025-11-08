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
  Map<String, String> _headers() {
    final h = <String, String>{};
    final ua = (settings.defaultUserAgent).trim();
    if (ua.isNotEmpty) h['user-agent'] = ua;
    final ref = (settings.defaultReferer ?? '').trim();
    if (ref.isNotEmpty) h['referer'] = ref;
    return h;
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
          // Poster avec bouton Play
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

          // Chips info
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: widget.item.groupTitle ?? 'Movie'),
              _Chip(text: host),
            ],
          ),

          const SizedBox(height: 12),

          // URL visible et sélectionnable
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

          // Actions
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
