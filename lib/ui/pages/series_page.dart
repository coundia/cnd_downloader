import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String q = '';
  String? group;

  @override
  void initState() {
    super.initState();
    _loadSavedGroup();
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
          final seriesCards = grouped.entries.map((e) {
            final episodes = e.value;
            final poster = episodes.firstWhere(
              (it) => (it.logo ?? '').isNotEmpty,
              orElse: () => episodes.first,
            );
            return SeriesCard(
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
              Expanded(
                child: LayoutBuilder(
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
                ),
              ),
            ],
          );
        },
      ),
    );
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
