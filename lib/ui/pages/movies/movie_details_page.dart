import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../data/iptv_models.dart';
import '../../../../core/settings.dart';
import '../../../../core/paths.dart';
import '../../../../viewmodels/download_list_vm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../widgets/cnd_video_player.dart';

class MovieDetailsPage extends ConsumerWidget {
  final IptvItem item;
  const MovieDetailsPage({super.key, required this.item});

  Map<String, String> _headers() {
    final h = <String, String>{};
    final ua = settings.defaultUserAgent.trim();
    if (ua.isNotEmpty) h['user-agent'] = ua;
    final ref = (settings.defaultReferer ?? '').trim();
    if (ref.isNotEmpty) h['referer'] = ref;
    return h;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headers = _headers();
    final theme = Theme.of(context);
    final host = _safeHost(item.streamUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Copy URL',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: item.streamUrl));
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('URL copied')));
              }
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Player en haut
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CndVideoPlayer(
                url: item.streamUrl,
                headers: headers,
                autoPlay: true,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Infos
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(text: item.groupTitle ?? 'Movie'),
              _Chip(text: host),
            ],
          ),
          const SizedBox(height: 12),

          // URL
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

          // Actions
          LayoutBuilder(
            builder: (c, bc) {
              final narrow = bc.maxWidth < 420;
              final watchBtn = Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    // player déjà présent; on remet play
                    // Pas de navigation supplémentaire
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Watch'),
                ),
              );

              final downloadBtn = Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final dir = await defaultDownloadDir();
                    await ref
                        .read(listVmProvider.notifier)
                        .addOnly(item.streamUrl, dir);
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
