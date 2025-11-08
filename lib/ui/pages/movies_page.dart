import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/iptv_models.dart';
import '../../../viewmodels/iptv_vm.dart';
import '../../../state/favorites_store.dart'; // NEW
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
    final favIds = ref.watch(favoritesProvider); // NEW

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

          // Split favoris / autres
          final favItems = filtered.where((e) => favIds.contains(e.id)).toList();
          final otherItems =
              filtered.where((e) => !favIds.contains(e.id)).toList();

          void onPick(IptvItem it) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MovieDetailsPage(item: it)),
              );
            });
          }

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

              return Column(
                children: [
                  // Barre de recherche / filtres
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
                    sortKeys: const ['Name', 'Group', 'Host', 'Rating'],
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

                  // Grilles
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        if (favItems.isNotEmpty) ...[
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 12, 12, 6),
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
                          _MoviesSliverGrid(
                            items: favItems,
                            cross: cross,
                            onSelect: onPick,
                            isFavorite: (it) => true,
                            onToggleFavorite: (it) => ref
                                .read(favoritesProvider.notifier)
                                .toggle(it.id),
                          ),
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Divider(height: 1),
                            ),
                          ),
                        ],
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                          sliver: const SliverToBoxAdapter(
                            child: Text(
                              'Tous les films',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        _MoviesSliverGrid(
                          items: otherItems,
                          cross: cross,
                          onSelect: onPick,
                          isFavorite: (it) => favIds.contains(it.id),
                          onToggleFavorite: (it) => ref
                              .read(favoritesProvider.notifier)
                              .toggle(it.id),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
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
          r = _safeHost(a.streamUrl)
              .toLowerCase()
              .compareTo(_safeHost(b.streamUrl).toLowerCase());
          break;
        case 'Rating':
          final ar = a.imdbRating ?? -1.0;
          final br = b.imdbRating ?? -1.0;
          r = ar.compareTo(br);
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
          final sel =
              (selected == null || selected!.isEmpty) ? isAll : selected == g;
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

/// Sliver grid réutilisable pour films.
class _MoviesSliverGrid extends StatelessWidget {
  final List<IptvItem> items;
  final int cross;
  final void Function(IptvItem) onSelect;
  final bool Function(IptvItem) isFavorite;
  final void Function(IptvItem) onToggleFavorite;

  const _MoviesSliverGrid({
    required this.items,
    required this.cross,
    required this.onSelect,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => _MovieTileFav(
          item: items[i],
          onTap: () => onSelect(items[i]),
          favorite: isFavorite(items[i]),
          onToggleFavorite: () => onToggleFavorite(items[i]),
        ),
        childCount: items.length,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cross,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.65,
      ),
    );
  }
}

class _MovieTileFav extends StatelessWidget {
  final IptvItem item;
  final VoidCallback onTap;
  final bool favorite;
  final VoidCallback onToggleFavorite;

  const _MovieTileFav({
    required this.item,
    required this.onTap,
    required this.favorite,
    required this.onToggleFavorite,
  });

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
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if ((poster ?? '').isNotEmpty)
                    Image.network(
                      poster!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF111111)),
                      loadingBuilder: (c, child, p) =>
                          p == null
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

                  // Badge rating
                  if (hasRating)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Bouton favori
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Material(
                      color: Colors.black.withOpacity(0.35),
                      shape: const CircleBorder(),
                      child: IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                        iconSize: 18,
                        tooltip:
                            favorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          favorite ? Icons.star : Icons.star_border,
                          color: favorite ? Colors.amber : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
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
