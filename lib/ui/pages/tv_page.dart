// lib/pages/tv_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';
import '../../core/settings.dart';
import '../widgets/cnd_video_player.dart';
import '../../state/favorites_store.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';
import '../../core/settings.dart';
import '../widgets/cnd_video_player.dart';

// NEW
import '../../state/favorites_store.dart';

class TvPage extends ConsumerStatefulWidget {
  const TvPage({super.key});
  @override
  ConsumerState<TvPage> createState() => _TvPageState();
}

class _TvPageState extends ConsumerState<TvPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(liveProvider);
    final vmState = ref.watch(iptvVmProvider);

    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher chaînes',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Erreur')),
            data: (list) {
              // filtre texte
              final filtered = q.isEmpty
                  ? list
                  : list
                        .where(
                          (e) => ('${e.name} ${e.groupTitle ?? ''}')
                              .toLowerCase()
                              .contains(q),
                        )
                        .toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('Aucune chaîne'));
              }

              // favoris actuels
              final favIds = ref.watch(favoritesProvider);
              final favItems = filtered
                  .where((e) => favIds.contains(e.id))
                  .toList();

              return LayoutBuilder(
                builder: (c, bc) {
                  final w = bc.maxWidth;
                  final cross = w >= 1600
                      ? 6
                      : w >= 1200
                      ? 5
                      : w >= 900
                      ? 4
                      : w >= 600
                      ? 3
                      : 2;

                  return CustomScrollView(
                    slivers: [
                      if (favItems.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                          sliver: const SliverToBoxAdapter(
                            child: Text(
                              'Favoris',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate((ctx, i) {
                              final it = favItems[i];
                              final isFav = favIds.contains(it.id);
                              return _ChannelCard(
                                item: it,
                                isFavorite: isFav,
                                onToggleFavorite: () => ref
                                    .read(favoritesProvider.notifier)
                                    .toggle(it.id),
                                onPlay: () => _openPlayer(it),
                              );
                            }, childCount: favItems.length),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cross,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 2.6,
                                ),
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Divider(height: 1),
                          ),
                        ),
                      ],
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                        sliver: const SliverToBoxAdapter(
                          child: Text(
                            'Toutes les chaînes',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((ctx, i) {
                            final it = filtered[i];
                            final isFav = favIds.contains(it.id);
                            return _ChannelCard(
                              item: it,
                              isFavorite: isFav,
                              onToggleFavorite: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(it.id),
                              onPlay: () => _openPlayer(it),
                            );
                          }, childCount: filtered.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: cross,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 2.6,
                              ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          vmState.isLoading
              ? const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Map<String, String> _headersFor(IptvItem it) {
    final map = <String, String>{};
    final ua = (it.userAgent ?? '').trim().isNotEmpty
        ? it.userAgent!.trim()
        : settings.defaultUserAgent.trim();
    if (ua.isNotEmpty) map['user-agent'] = ua;
    final refh = (it.referer ?? '').trim().isNotEmpty
        ? it.referer!.trim()
        : (settings.defaultReferer ?? '').trim();
    if (refh.isNotEmpty) map['referer'] = refh;
    final hj = (it.headersJson ?? '').trim();
    if (hj.isNotEmpty) {
      try {
        final m = Map<String, dynamic>.from(json.decode(hj) as Map);
        m.forEach((k, v) {
          final key = k.toString();
          final val = v?.toString() ?? '';
          if (val.isNotEmpty) map[key] = val;
        });
      } catch (_) {}
    }
    return map;
  }

  void _openPlayer(IptvItem it) {
    final url = (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl;
    final headers = _headersFor(it);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _LivePlayerPage(title: it.name, url: url, headers: headers),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final IptvItem item;
  final VoidCallback onPlay;

  // NEW
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const _ChannelCard({
    required this.item,
    required this.onPlay,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPlay,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              if ((item.logo ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Image.network(
                    item.logo!,
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox(width: 36, height: 36),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.groupTitle ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: isFavorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : null,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.play_arrow),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePlayerPage extends StatelessWidget {
  final String title;
  final String url;
  final Map<String, String> headers;
  const _LivePlayerPage({
    required this.title,
    required this.url,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Copier l’URL',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('URL copiée')));
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CndVideoPlayer(url: url, headers: headers, autoPlay: true),
          ),
        ),
      ),
    );
  }
}
