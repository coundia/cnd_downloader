import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/iptv_models.dart';
import '../../../viewmodels/iptv_vm.dart';
import '../../../state/favorites_store.dart';
import 'movies/movie_details_page.dart';
import 'widgets/search_filter_bar.dart';

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});
  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> {
  static const _prefKeyGroup = 'movies.selectedGroup';
  static const _prefKeyView = 'movies.viewMode';

  String q = '';
  String? group;
  String? host;
  String sortKey = 'Name';
  bool sortAsc = true;

  bool listMode = false;

  @override
  void initState() {
    super.initState();
    _loadSavedGroup();
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

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(moviesProvider);
    final favIds = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
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
        loading: () => const _PageLoading(),
        error: (_, __) => const _PageError(),
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

          final favItems = filtered
              .where((e) => favIds.contains(e.id))
              .toList();
          final otherItems = filtered
              .where((e) => !favIds.contains(e.id))
              .toList();

          void onPick(IptvItem it) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MovieDetailsPage(item: it)),
              );
            });
          }

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
                sortKeys: const ['Name', 'Group', 'Host', 'Rating'],
                selectedSortKey: sortKey,
                onSelectSortKey: (v) => setState(() => sortKey = v ?? 'Name'),
                sortAsc: sortAsc,
                onToggleAsc: () => setState(() => sortAsc = !sortAsc),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: _StatsRow(
                  total: filtered.length,
                  fav: favItems.length,
                  query: q,
                ),
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
              Expanded(
                child: filtered.isEmpty
                    ? const _EmptyState()
                    : CustomScrollView(
                        slivers: [
                          if (favItems.isNotEmpty) ...[
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                              sliver: SliverToBoxAdapter(
                                child: _SectionHeader(
                                  title: 'Favoris',
                                  count: favItems.length,
                                ),
                              ),
                            ),
                            SliverPadding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              sliver: listMode
                                  ? _MoviesSliverList(
                                      items: favItems,
                                      onSelect: onPick,
                                      isFavorite: (_) => true,
                                      onToggleFavorite: (it) => ref
                                          .read(favoritesProvider.notifier)
                                          .toggle(it.id),
                                    )
                                  : _MoviesSliverGrid(
                                      items: favItems,
                                      cross: _crossCountFor(
                                        MediaQuery.sizeOf(context).width,
                                      ),
                                      onSelect: onPick,
                                      isFavorite: (_) => true,
                                      onToggleFavorite: (it) => ref
                                          .read(favoritesProvider.notifier)
                                          .toggle(it.id),
                                    ),
                            ),
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Divider(height: 1),
                              ),
                            ),
                          ],
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                            sliver: SliverToBoxAdapter(
                              child: _SectionHeader(
                                title: 'Tous les films',
                                count: otherItems.length,
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            sliver: listMode
                                ? _MoviesSliverList(
                                    items: otherItems,
                                    onSelect: onPick,
                                    isFavorite: (it) => favIds.contains(it.id),
                                    onToggleFavorite: (it) => ref
                                        .read(favoritesProvider.notifier)
                                        .toggle(it.id),
                                  )
                                : _MoviesSliverGrid(
                                    items: otherItems,
                                    cross: _crossCountFor(
                                      MediaQuery.sizeOf(context).width,
                                    ),
                                    onSelect: onPick,
                                    isFavorite: (it) => favIds.contains(it.id),
                                    onToggleFavorite: (it) => ref
                                        .read(favoritesProvider.notifier)
                                        .toggle(it.id),
                                  ),
                          ),
                          const SliverToBoxAdapter(child: SizedBox(height: 12)),
                        ],
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
        : w >= 1400
        ? 6
        : w >= 1200
        ? 5
        : w >= 900
        ? 4
        : w >= 600
        ? 3
        : 2;
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

class _StatsRow extends StatelessWidget {
  final int total;
  final int fav;
  final String query;

  const _StatsRow({
    required this.total,
    required this.fav,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(Icons.movie, size: 18),
          label: Text('Films: $total'),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: const Icon(Icons.star, size: 18),
          label: Text('Favoris: $fav'),
          visualDensity: VisualDensity.compact,
        ),
        if (query.trim().isNotEmpty)
          ActionChip(
            avatar: const Icon(Icons.search, size: 18),
            label: Text('“${query.trim()}”'),
            onPressed: () {},
          ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          title,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Text(
          '$count',
          style: t.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
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

class _MoviesSliverList extends StatelessWidget {
  final List<IptvItem> items;
  final void Function(IptvItem) onSelect;
  final bool Function(IptvItem) isFavorite;
  final void Function(IptvItem) onToggleFavorite;

  const _MoviesSliverList({
    required this.items,
    required this.onSelect,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final it = items[i];
        final fav = isFavorite(it);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MovieRowTile(
            item: it,
            favorite: fav,
            onTap: () => onSelect(it),
            onToggleFavorite: () => onToggleFavorite(it),
          ),
        );
      }, childCount: items.length),
    );
  }
}

class _MovieRowTile extends StatelessWidget {
  final IptvItem item;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  const _MovieRowTile({
    required this.item,
    required this.favorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rating = item.imdbRating ?? 0;
    final hasRating = rating > 0 && rating < 10;
    final poster = item.logo;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 96,
                  child: (poster ?? '').isNotEmpty
                      ? Image.network(
                          poster!,
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
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.groupTitle ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (hasRating)
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              IconButton(
                tooltip: favorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
                onPressed: onToggleFavorite,
                icon: Icon(favorite ? Icons.star : Icons.star_border),
                color: favorite ? Colors.amber : cs.onSurfaceVariant,
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

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
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final it = items[i];
        return _MovieTileFav(
          item: it,
          onTap: () => onSelect(it),
          favorite: isFavorite(it),
          onToggleFavorite: () => onToggleFavorite(it),
        );
      }, childCount: items.length),
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
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
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
                        tooltip: favorite
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
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
          Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            item.groupTitle ?? '',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PageLoading extends StatelessWidget {
  const _PageLoading();
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _PageError extends StatelessWidget {
  const _PageError();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Error'));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 44),
              const SizedBox(height: 12),
              Text(
                'Aucun film',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Modifiez la recherche ou les filtres.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
