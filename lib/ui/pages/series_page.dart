import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';
import 'series_details_page.dart';

class SeriesPage extends ConsumerStatefulWidget {
  const SeriesPage({super.key});
  @override
  ConsumerState<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends ConsumerState<SeriesPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(seriesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Séries'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher séries',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur')),
        data: (list) {
          final filtered = _filter(list, q);
          if (filtered.isEmpty) {
            return const Center(child: Text('Aucune série'));
          }
          final grouped = _groupBySeries(filtered);
          final seriesCards = grouped.entries.map((e) {
            final episodes = e.value;
            // Choisir un poster représentatif
            final poster = episodes.firstWhere(
              (it) => (it.logo ?? '').isNotEmpty,
              orElse: () => episodes.first,
            );
            return _SeriesCard(
              title: e.key,
              posterUrl: poster.logo,
              count: episodes.length,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        SeriesDetailsPage(seriesKey: e.key, episodes: episodes),
                  ),
                );
              },
            );
          }).toList();

          return LayoutBuilder(
            builder: (c, bc) {
              final w = bc.maxWidth;
              final cross = w >= 1600
                  ? 7
                  : w >= 1200
                  ? 6
                  : w >= 900
                  ? 5
                  : w >= 600
                  ? 4
                  : 3;
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: .72,
                ),
                itemCount: seriesCards.length,
                itemBuilder: (_, i) => seriesCards[i],
              );
            },
          );
        },
      ),
    );
  }

  List<IptvItem> _filter(List<IptvItem> list, String q) {
    if (q.isEmpty) return list;
    return list
        .where(
          (e) => ('${e.name} ${e.groupTitle ?? ''}').toLowerCase().contains(q),
        )
        .toList();
  }

  // Regroupe par “clé série” (nom nettoyé sans SxxEyy, tags, qualité…)
  Map<String, List<IptvItem>> _groupBySeries(List<IptvItem> list) {
    final map = SplayTreeMap<String, List<IptvItem>>((a, b) => a.compareTo(b));
    for (final it in list) {
      final key = _seriesKey(it.name);
      map.putIfAbsent(key, () => <IptvItem>[]).add(it);
    }
    // tri interne par saison/épisode
    for (final episodes in map.values) {
      episodes.sort((a, b) {
        final as = _parseSeason(a.name);
        final bs = _parseSeason(b.name);
        final ae = _parseEpisode(a.name);
        final be = _parseEpisode(b.name);
        final r1 = as.compareTo(bs);
        if (r1 != 0) return r1;
        final r2 = ae.compareTo(be);
        if (r2 != 0) return r2;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }
    return map;
  }

  String _seriesKey(String raw) {
    var s = raw;
    s = s.replaceAll(RegExp(r'\[[^\]]*\]|\([^\)]*\)|\{[^\}]*\}'), ' ');
    s = s.replaceAll(
      RegExp(
        r'(?:S|Season)\s*\d{1,2}\s*(?:E|Ep|Episode)?\s*\d{1,3}',
        caseSensitive: false,
      ),
      ' ',
    );
    s = s.replaceAll(
      RegExp(r'(?:E|Ep|Episode)\s*\d{1,3}', caseSensitive: false),
      ' ',
    );
    s = s.replaceAll(
      RegExp(
        r'\b(1080p|720p|2160p|4K|HDR|VOSTFR|TRUEFRENCH|MULTI|WEB[- ]?DL|BRRip|x264|x265)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    s = s.replaceAll(RegExp(r'\s+[-–—·•]\s+'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  int _parseSeason(String name) {
    final m = RegExp(r'[Ss]\s*(\d{1,2})').firstMatch(name);
    if (m != null) return int.tryParse(m.group(1)!) ?? 1;
    final m2 = RegExp(
      r'Season\s*(\d{1,2})',
      caseSensitive: false,
    ).firstMatch(name);
    if (m2 != null) return int.tryParse(m2.group(1)!) ?? 1;
    return 1;
  }

  int _parseEpisode(String name) {
    final m = RegExp(r'[Ee]\s*(\d{1,3})').firstMatch(name);
    if (m != null) return int.tryParse(m.group(1)!) ?? 1;
    final m2 = RegExp(
      r'(?:Ep|Episode)\s*(\d{1,3})',
      caseSensitive: false,
    ).firstMatch(name);
    if (m2 != null) return int.tryParse(m2.group(1)!) ?? 1;
    // fallback: nombre en fin
    final m3 = RegExp(r'(\d{1,3})$').firstMatch(name.trim());
    if (m3 != null) return int.tryParse(m3.group(1)!) ?? 1;
    return 1;
  }
}

class _SeriesCard extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final int count;
  final VoidCallback onTap;
  const _SeriesCard({
    required this.title,
    required this.posterUrl,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: (posterUrl ?? '').isNotEmpty
                  ? Image.network(
                      posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFEEEEEE)),
                    )
                  : const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('$count'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
