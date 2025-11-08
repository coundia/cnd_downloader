import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/paths.dart';
import '../../../../core/settings.dart';
import '../../../../viewmodels/download_list_vm.dart';
import '../../../../data/iptv_models.dart';

// + NEW
import '../../../../services/movie_meta_service.dart';
import '../../widgets/cnd_video_player.dart';

class MovieDetailsPane extends ConsumerWidget {
  final IptvItem item;
  const MovieDetailsPane({super.key, required this.item});

  Map<String, String> _headers() {
    final h = <String, String>{};
    if ((settings.defaultUserAgent).trim().isNotEmpty) {
      h['user-agent'] = settings.defaultUserAgent;
    }
    if ((settings.defaultReferer ?? '').trim().isNotEmpty) {
      h['referer'] = settings.defaultReferer!.trim();
    }
    return h;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final headers = _headers();

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Scrollbar(
          thumbVisibility: true,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy URL',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: item.streamUrl),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URL copied')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Player intégré
              CndVideoPlayer(
                url: item.streamUrl,
                headers: headers,
                autoPlay: true,
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip(text: item.groupTitle ?? 'Movie'),
                    _Chip(text: _host(item.streamUrl)),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ---- NEW: Carte Synopsis via OMDb ----
              _SynopsisCard(title: item.name, fallbackPoster: item.logo),

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
                    item.streamUrl,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _ActionsBar(streamUrl: item.streamUrl),
            ],
          ),
        ),
      ),
    );
  }

  String _host(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return 'unknown';
    }
  }
}

class _SynopsisCard extends ConsumerStatefulWidget {
  final String title;
  final String? fallbackPoster;

  const _SynopsisCard({required this.title, this.fallbackPoster});

  @override
  ConsumerState<_SynopsisCard> createState() => _SynopsisCardState();
}

class _SynopsisCardState extends ConsumerState<_SynopsisCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(movieSynopsisProvider(widget.title));

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: async.when(
          loading: () => Row(
            children: const [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Chargement du résumé…'),
            ],
          ),
          error: (_, __) =>
              _EmptyOrHint(text: 'Résumé indisponible pour le moment.'),
          data: (syn) {
            if (syn == null) {
              // Astuce si la clé OMDb manque
              return _EmptyOrHint(
                text:
                    'Aucun résumé trouvé. Configure OMDb: '
                    '--dart-define=OMDB_API_KEY=TA_CLE',
              );
            }

            final poster = syn.poster ?? widget.fallbackPoster;
            final metaLine = [
              if (syn.year != null) syn.year,
              if (syn.runtime != null) syn.runtime,
              if (syn.rating != null) 'IMDb ${syn.rating}',
            ].whereType<String>().join(' • ');

            final plot = syn.plot ?? 'Résumé non fourni.';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (poster != null && poster.isNotEmpty)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      poster,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF111111)),
                    ),
                  ),
                if (poster != null && poster.isNotEmpty)
                  const SizedBox(height: 8),
                if (metaLine.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(metaLine, style: theme.textTheme.bodySmall),
                  ),
                if (syn.genres.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: syn.genres
                        .map((g) => _TinyChip(text: g))
                        .toList(),
                  ),
                if (syn.genres.isNotEmpty) const SizedBox(height: 8),

                // Plot avec "voir plus / moins"
                _ExpandableText(
                  text: plot,
                  expanded: _expanded,
                  onToggle: () => setState(() => _expanded = !_expanded),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ExpandableText extends StatelessWidget {
  final String text;
  final bool expanded;
  final VoidCallback onToggle;
  const _ExpandableText({
    required this.text,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium;
    final max = expanded ? 1000 : 5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: max,
          overflow: TextOverflow.ellipsis,
          style: style,
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onToggle,
            child: Text(expanded ? 'Voir moins' : 'Voir plus'),
          ),
        ),
      ],
    );
  }
}

class _EmptyOrHint extends StatelessWidget {
  final String text;
  const _EmptyOrHint({required this.text});
  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.bodySmall);
  }
}

class _ActionsBar extends ConsumerWidget {
  final String streamUrl;
  const _ActionsBar({required this.streamUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (c, bc) {
        final narrow = bc.maxWidth < 360;

        final watchBtn = Expanded(
          child: FilledButton.icon(
            onPressed: () => _openUrlExternally(streamUrl, context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Watch in app'),
          ),
        );

        final downloadBtn = Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final dir = await defaultDownloadDir();
              await ref.read(listVmProvider.notifier).addOnly(streamUrl, dir);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Queued to Downloads')),
                );
              }
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
    );
  }

  Future<void> _openUrlExternally(String url, BuildContext context) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('/usr/bin/open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Open failed: $e')));
      }
    }
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

class _TinyChip extends StatelessWidget {
  final String text;
  const _TinyChip({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
