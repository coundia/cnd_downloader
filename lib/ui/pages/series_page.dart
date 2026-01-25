// lib/pages/series/series_page.dart
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../services/open_external.dart';
import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';
import 'seriesCard.dart';
import 'series_details_page.dart';

class SeriesPage extends ConsumerStatefulWidget {
  const SeriesPage({super.key});
  @override
  ConsumerState<SeriesPage> createState() => _SeriesPageState();
}

class _SeriesPageState extends ConsumerState<SeriesPage> {
  static const _prefKeyGroup = 'series.selectedGroup';
  static const _prefKeyFavs = 'series.favs';
  static const _prefKeyView = 'series.viewMode';

  String q = '';
  String? group;
  bool listMode = false;

  final Set<String> _favs = {};

  @override
  void initState() {
    super.initState();
    _loadSavedGroup();
    _loadSavedFavs();
    _loadViewMode();
  }

  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getBool(_prefKeyView) ?? false;
    if (!mounted) return;
    setState(() => listMode = v);
  }

  Future<void> _persistViewMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyView, v);
  }

  Future<void> _loadSavedGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKeyGroup);
    if (!mounted) return;
    setState(() => group = (saved == null || saved.isEmpty) ? null : saved);
  }

  Future<void> _persistGroup(String? g) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyGroup, g ?? '');
  }

  Future<void> _loadSavedFavs() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefKeyFavs) ?? const <String>[];
    if (!mounted) return;
    setState(() {
      _favs
        ..clear()
        ..addAll(list);
    });
  }

  Future<void> _persistFavs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefKeyFavs, _favs.toList());
  }

  Future<void> _toggleFav(String seriesKey) async {
    setState(() {
      if (_favs.contains(seriesKey)) {
        _favs.remove(seriesKey);
      } else {
        _favs.add(seriesKey);
      }
    });
    await _persistFavs();
  }

  String _seriesMediaUrl(List<IptvItem> episodes) {
    if (episodes.isEmpty) return '';
    final first = episodes.first;
    final u = (first.realUrl ?? '').trim();
    return u.isNotEmpty ? u : first.streamUrl;
  }

  Future<void> _openExternal(
    BuildContext context,
    List<IptvItem> episodes,
  ) async {
    final url = _seriesMediaUrl(episodes);
    if (url.trim().isEmpty) return;
    try {
      await ExternalPlayer.open(url);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir le lecteur externe'),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _download(BuildContext context, List<IptvItem> episodes) async {
    final url = _seriesMediaUrl(episodes);
    if (url.trim().isEmpty) return;
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir/télécharger'),
          behavior: SnackBarBehavior.floating,
          showCloseIcon: true,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _openDetails(BuildContext context, String key, List<IptvItem> episodes) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SeriesDetailsPage(seriesKey: key, episodes: episodes),
      ),
    );
  }

  void _showQuickDetails(
    BuildContext context,
    String key,
    List<IptvItem> episodes,
  ) {
    final poster = episodes.firstWhere(
      (it) => (it.logo ?? '').isNotEmpty,
      orElse: () => episodes.first,
    );
    final groupTitle = (poster.groupTitle ?? '').trim();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(key),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Épisodes: ${episodes.length}'),
            if (groupTitle.isNotEmpty) Text('Groupe: $groupTitle'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

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
        actions: [
          IconButton(
            tooltip: 'Mode liste',
            isSelected: listMode,
            onPressed: () async {
              setState(() => listMode = true);
              await _persistViewMode(true);
            },
            icon: const Icon(Icons.view_list),
          ),
          IconButton(
            tooltip: 'Mode grille',
            isSelected: !listMode,
            onPressed: () async {
              setState(() => listMode = false);
              await _persistViewMode(false);
            },
            icon: const Icon(Icons.grid_view),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erreur')),
        data: (list) {
          final allGroups = _uniqueGroups(list);

          if (group != null && !allGroups.contains(group)) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              setState(() => group = null);
              await _persistGroup(null);
            });
          }

          final filtered = _filter(list, q, group);
          if (filtered.isEmpty) {
            return const Center(child: Text('Aucune série'));
          }

          final grouped = _groupBySeries(filtered);
          final favEntries = grouped.entries
              .where((e) => _favs.contains(e.key))
              .toList();
          final otherEntries = grouped.entries
              .where((e) => !_favs.contains(e.key))
              .toList();

          Widget buildCard(MapEntry<String, List<IptvItem>> e) {
            final episodes = e.value;
            final poster = episodes.firstWhere(
              (it) => (it.logo ?? '').isNotEmpty,
              orElse: () => episodes.first,
            );

            return SeriesCard(
              title: e.key,
              posterUrl: poster.logo,
              count: episodes.length,
              isFavorite: _favs.contains(e.key),
              onToggleFavorite: () => _toggleFav(e.key),
              onTap: () => _openDetails(context, e.key, episodes),
              actions: SeriesCardActions(
                onRead: () => _openDetails(context, e.key, episodes),
                onDetails: () => _showQuickDetails(context, e.key, episodes),
                onExternal: () => _openExternal(context, episodes),
                onDownload: () => _download(context, episodes),
              ),
            );
          }

          return Column(
            children: [
              _GroupChipsBar(
                groups: allGroups,
                selected: group,
                onSelect: (g) async {
                  final sel = (g == null || g.isEmpty) ? null : g;
                  setState(() => group = sel);
                  await _persistGroup(sel);
                },
              ),
              const Divider(height: 1),
              if (favEntries.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Text(
                        'Favoris',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${favEntries.length}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 290,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (_, i) =>
                        SizedBox(width: 190, child: buildCard(favEntries[i])),
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemCount: favEntries.length,
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (c, bc) {
                    final cross = _crossCountFor(bc.maxWidth);

                    if (listMode) {
                      return ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: otherEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          return _SeriesRowTile(
                            entry: otherEntries[i],
                            isFavorite: _favs.contains(otherEntries[i].key),
                            onToggleFavorite: () =>
                                _toggleFav(otherEntries[i].key),
                            onRead: () => _openDetails(
                              context,
                              otherEntries[i].key,
                              otherEntries[i].value,
                            ),
                            onDetails: () => _showQuickDetails(
                              context,
                              otherEntries[i].key,
                              otherEntries[i].value,
                            ),
                            onExternal: () =>
                                _openExternal(context, otherEntries[i].value),
                            onDownload: () =>
                                _download(context, otherEntries[i].value),
                          );
                        },
                      );
                    }

                    return MasonryGridView.count(
                      padding: const EdgeInsets.all(12),
                      crossAxisCount: cross,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      itemCount: otherEntries.length,
                      itemBuilder: (_, i) => buildCard(otherEntries[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _crossCountFor(double w) {
    return w >= 1600
        ? 7
        : w >= 1200
        ? 6
        : w >= 900
        ? 5
        : w >= 600
        ? 4
        : 2;
  }

  List<IptvItem> _filter(List<IptvItem> list, String q, String? group) {
    final ql = q.toLowerCase().trim();
    return list.where((e) {
      final hitQuery =
          ql.isEmpty ||
          ('${e.name} ${e.groupTitle ?? ''}').toLowerCase().contains(ql);
      final hitGroup =
          (group == null || group.isEmpty) ||
          (e.groupTitle ?? 'Other') == group;
      return hitQuery && hitGroup;
    }).toList();
  }

  Map<String, List<IptvItem>> _groupBySeries(List<IptvItem> list) {
    final map = SplayTreeMap<String, List<IptvItem>>((a, b) => a.compareTo(b));
    for (final it in list) {
      final key = _seriesKey(it.name);
      map.putIfAbsent(key, () => <IptvItem>[]).add(it);
    }
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
    final m3 = RegExp(r'(\d{1,3})$').firstMatch(name.trim());
    if (m3 != null) return int.tryParse(m3.group(1)!) ?? 1;
    return 1;
  }

  List<String> _uniqueGroups(List<IptvItem> list) {
    final set = SplayTreeSet<String>();
    for (final e in list) {
      set.add((e.groupTitle ?? 'Other').trim());
    }
    return [''].followedBy(set).toList();
  }
}

class _GroupChipsBar extends StatelessWidget {
  final List<String> groups;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _GroupChipsBar({
    required this.groups,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        scrollDirection: Axis.horizontal,
        itemCount: groups.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final g = groups[i];
          final isAll = g.isEmpty;
          final label = isAll ? 'Tous' : g;
          final sel = (selected == null || selected!.isEmpty)
              ? isAll
              : selected == g;

          return ChoiceChip(
            label: Text(label, overflow: TextOverflow.ellipsis),
            selected: sel,
            onSelected: (_) => onSelect(isAll ? '' : g),
          );
        },
      ),
    );
  }
}

class _SeriesRowTile extends StatelessWidget {
  final MapEntry<String, List<IptvItem>> entry;
  final bool isFavorite;

  final VoidCallback onToggleFavorite;
  final VoidCallback onRead;
  final VoidCallback onDetails;
  final VoidCallback onExternal;
  final VoidCallback onDownload;

  const _SeriesRowTile({
    required this.entry,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRead,
    required this.onDetails,
    required this.onExternal,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final episodes = entry.value;

    final poster = episodes.firstWhere(
      (it) => (it.logo ?? '').isNotEmpty,
      orElse: () => episodes.first,
    );

    return InkWell(
      onTap: onRead,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 96,
                  child: (poster.logo ?? '').isNotEmpty
                      ? Image.network(
                          poster.logo!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const ColoredBox(color: Color(0xFF111111)),
                        )
                      : const ColoredBox(color: Color(0xFF111111)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${episodes.length} épisodes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TinyAction(
                          icon: Icons.menu_book,
                          label: 'Lire',
                          onTap: onRead,
                        ),
                        _TinyAction(
                          icon: Icons.info_outline,
                          label: 'Détails',
                          onTap: onDetails,
                        ),
                        _TinyAction(
                          icon: Icons.open_in_new,
                          label: 'Externe',
                          onTap: onExternal,
                        ),
                        _TinyAction(
                          icon: Icons.download,
                          label: 'Télécharger',
                          onTap: onDownload,
                        ),
                      ],
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
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                color: isFavorite ? Colors.amber : cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TinyAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(label, style: Theme.of(context).textTheme.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}
