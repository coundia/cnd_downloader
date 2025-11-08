import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/iptv_models.dart';
import '../../../viewmodels/iptv_vm.dart';
import 'movies/movie_details_page.dart';
import 'widgets/search_filter_bar.dart';

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});
  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> {
  static const _prefKeyGroup = 'movies.selectedGroup';

  String q = '';
  String? group;
  String? host;
  String sortKey = 'Name';
  bool sortAsc = true;

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
    final items = ref.watch(moviesProvider);

    return Scaffold(
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
        data: (list) {
          final allGroups = _uniqueGroups(list);
          final allHosts = _uniqueHosts(list);

          if (group != null && !allGroups.contains(group)) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (!mounted) return;
              setState(() => group = null);
              await _persistGroup(null);
            });
          }

          final ql = q.toLowerCase().trim();
          final filtered = list.where((e) {
            final hitQuery =
                ql.isEmpty ||
                ('${e.name} ${e.groupTitle ?? ''}').toLowerCase().contains(ql);
            final hitGroup =
                (group == null || group!.isEmpty) ||
                (e.groupTitle ?? 'Other') == group;
            final h = _safeHost(e.streamUrl);
            final hitHost = (host == null || host!.isEmpty) || h == host;
            return hitQuery && hitGroup && hitHost;
          }).toList();

          _sortInPlace(filtered, sortKey, sortAsc);

          void onPick(IptvItem it) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MovieDetailsPage(item: it)),
              );
            });
          }

          final identity = [
            q,
            group ?? '',
            host ?? '',
            sortKey,
            sortAsc ? 'asc' : 'desc',
            filtered.length.toString(),
          ].join('|');

          final grid = MovieGridWithRatings(
            items: filtered,
            onSelect: onPick,
            identity: identity,
          );

          return Column(
            children: [
              SearchFilterBar(
                query: q,
                onQuery: (v) => setState(() => q = v),
                groups: allGroups,
                selectedGroup: group,
                onSelectGroup: (v) async {
                  final sel = (v == null || v.isEmpty) ? null : v;
                  setState(() => group = sel);
                  await _persistGroup(sel);
                },
                hosts: allHosts,
                selectedHost: host,
                onSelectHost: (v) => setState(() => host = v),
                sortKeys: const ['Name', 'Group', 'Host'],
                selectedSortKey: sortKey,
                onSelectSortKey: (v) => setState(() => sortKey = v ?? 'Name'),
                sortAsc: sortAsc,
                onToggleAsc: () => setState(() => sortAsc = !sortAsc),
              ),
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
              Expanded(child: grid),
            ],
          );
        },
      ),
    );
  }

  List<String> _uniqueGroups(List<IptvItem> list) {
    final set = SplayTreeSet<String>();
    for (final e in list) {
      set.add((e.groupTitle ?? 'Other').trim());
    }
    return [''].followedBy(set).toList();
  }

  List<String> _uniqueHosts(List<IptvItem> list) {
    final set = SplayTreeSet<String>();
    for (final e in list) {
      final h = _safeHost(e.streamUrl);
      if (h.isNotEmpty) set.add(h);
    }
    return [''].followedBy(set).toList();
  }

  String _safeHost(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
  }

  void _sortInPlace(List<IptvItem> list, String key, bool asc) {
    int cmp(IptvItem a, IptvItem b) {
      int r;
      switch (key) {
        case 'Group':
          r = (a.groupTitle ?? 'Other').toLowerCase().compareTo(
            (b.groupTitle ?? 'Other').toLowerCase(),
          );
          break;
        case 'Host':
          r = _safeHost(
            a.streamUrl,
          ).toLowerCase().compareTo(_safeHost(b.streamUrl).toLowerCase());
          break;
        default:
          r = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
      return asc ? r : -r;
    }

    list.sort(cmp);
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
          final label = isAll ? 'All' : g;
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

class MovieGridWithRatings extends StatelessWidget {
  final List<IptvItem> items;
  final void Function(IptvItem) onSelect;
  final String identity;

  const MovieGridWithRatings({
    super.key,
    required this.items,
    required this.onSelect,
    required this.identity,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (c, bc) {
        final w = bc.maxWidth;
        final cross = w >= 1600
            ? 7
            : w >= 1400
            ? 6
            : w >= 1200
            ? 5
            : w >= 900
            ? 4
            : w >= 600
            ? 3
            : 2;
        return GridView.builder(
          key: ValueKey(identity),
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            // Slightly taller tiles reduce overflow risk on large text scales
            childAspectRatio: 0.65,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) =>
              _MovieTile(item: items[i], onTap: () => onSelect(items[i])),
        );
      },
    );
  }
}

class _MovieTile extends StatelessWidget {
  final IptvItem item;
  final VoidCallback onTap;

  const _MovieTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rating = item.imdbRating ?? 0;
    final hasRating = rating > 0 && rating < 10;
    final poster = item.logo;

    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poster stretches to fill remaining height
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Use FittedBox behavior via BoxFit.cover so aspect is preserved without fixed height
                  if ((poster ?? '').isNotEmpty)
                    Image.network(
                      poster!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF111111)),
                      loadingBuilder: (c, child, p) => p == null
                          ? child
                          : const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                    )
                  else
                    const ColoredBox(color: Color(0xFF111111)),
                  if (hasRating)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Texts are Flexible to avoid forcing extra height
          Flexible(
            child: Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              item.groupTitle ?? '',
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
