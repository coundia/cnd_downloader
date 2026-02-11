import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../../data/iptv_models.dart';
import '../../../viewmodels/iptv_vm.dart';
import '../../../state/favorites_store.dart';
import '../../services/open_external.dart';
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

  String _mediaUrl(IptvItem it) {
    final u = (it.realUrl ?? '').trim();
    return u.isNotEmpty ? u : it.streamUrl;
  }

  Future<void> _download(BuildContext context, IptvItem it) async {
    final url = _mediaUrl(it);
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

  Future<void> _openExternal(BuildContext context, IptvItem it) async {
    final url = _mediaUrl(it);
    try {
      await ExternalPlayer.open(url);
    } catch (_) {
      if (context.mounted) {
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
  }

  void _openDetailsPage(BuildContext context, IptvItem it) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => MovieDetailsPage(item: it)));
    });
  }

  void _showQuickDetails(BuildContext context, IptvItem it) {
    final host = _safeHost(it.streamUrl);
    final rating = it.imdbRating ?? 0;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(it.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((it.groupTitle ?? '').trim().isNotEmpty)
              Text('Groupe: ${it.groupTitle}'),
            if (host.isNotEmpty) Text('Host: $host'),
            if (rating > 0) Text('IMDb: ${rating.toStringAsFixed(1)}'),
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
    final vmState = ref.watch(moviesVmProvider);
    final iptvState = ref.watch(iptvVmProvider);
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
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (!vmState.isLoading && 
                  vmState.hasMore && 
                  scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                ref.read(moviesVmProvider.notifier).loadNext();
              }
              return false;
            },
            child: LayoutBuilder(
              builder: (c, bc) {
                final cross = _crossCountFor(bc.maxWidth);
                final items = vmState.items;
                
                final favItems = items
                  .where((e) => favIds.contains(e.id))
                  .toList();
                final otherItems = items
                  .where((e) => !favIds.contains(e.id))
                  .toList();
                  
                return Column(
                  children: [
                    // We need FutureBuilders for aggregates since we can't derive them easily from partial list
                    FutureBuilder<List<String>>(
                      future: ref.read(moviesVmProvider.notifier).getAvailableGroups(),
                      builder: (context, snapshotGroups) {
                        return FutureBuilder<List<String>>(
                           future: ref.read(moviesVmProvider.notifier).getAvailableHosts(),
                           builder: (context, snapshotHosts) {
                             return SearchFilterBar(
                                query: vmState.query,
                                onQuery: (v) => ref.read(moviesVmProvider.notifier).setQuery(v),
                                groups: ['', ...?snapshotGroups.data],
                                selectedGroup: vmState.group,
                                onSelectGroup: (v) async {
                                  final sel = (v == null || v.isEmpty) ? null : v;
                                  ref.read(moviesVmProvider.notifier).setGroup(sel);
                                  await _persistGroup(sel);
                                },
                                hosts: ['', ...?snapshotHosts.data],
                                selectedHost: vmState.host,
                                onSelectHost: (v) => ref.read(moviesVmProvider.notifier).setHost(v),
                                sortKeys: const ['Name', 'Group', 'Host', 'Rating'],
                                selectedSortKey: vmState.sortKey,
                                onSelectSortKey: (v) =>
                                    ref.read(moviesVmProvider.notifier).setSort(v ?? 'Name', vmState.sortAsc),
                                sortAsc: vmState.sortAsc,
                                onToggleAsc: () => ref.read(moviesVmProvider.notifier).setSort(vmState.sortKey, !vmState.sortAsc),
                              );
                           }
                         );
                      }
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                      child: _StatsRow(
                        total: items.length, // Showing cached count
                        fav: favItems.length,
                        query: vmState.query,
                      ),
                    ),
                    // Group chips logic is duplicated from filter bar, skipping here or keeping if useful.
                    // The _GroupChipsBar was useful for quick access. 
                    // We can reuse the FutureBuilder result if we refactored, but for now simple:
                     FutureBuilder<List<String>>(
                      future: ref.read(moviesVmProvider.notifier).getAvailableGroups(),
                      builder: (context, snapshot) {
                        return _GroupChipsBar(
                          groups: snapshot.data ?? [],
                          selected: vmState.group,
                          onSelect: (g) async {
                            final sel = (g == null || g.isEmpty) ? null : g;
                            ref.read(moviesVmProvider.notifier).setGroup(sel);
                            await _persistGroup(sel);
                          },
                        );
                      }
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: vmState.items.isEmpty
                          ? _EmptyState(
                              onClear: () {
                                ref.read(moviesVmProvider.notifier).setQuery('');
                                ref.read(moviesVmProvider.notifier).setGroup(null);
                                ref.read(moviesVmProvider.notifier).setHost(null);
                              },
                            )
                          : CustomScrollView(
                              slivers: [
                                if (favItems.isNotEmpty) ...[
                                  SliverPadding(
                                    padding: const EdgeInsets.fromLTRB(
                                      12,
                                      12,
                                      12,
                                      6,
                                    ),
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
                                            isFavorite: (_) => true,
                                            onToggleFavorite: (it) => ref.read(favoritesProvider.notifier).toggle(it.id),
                                            onRead: (it) =>
                                                _openDetailsPage(context, it),
                                            onDetails: (it) =>
                                                _showQuickDetails(context, it),
                                            onExternal: (it) =>
                                                _openExternal(context, it),
                                            onDownload: (it) =>
                                                _download(context, it),
                                          )
                                        : _MoviesSliverMasonryGrid(
                                            items: favItems,
                                            cross: cross,
                                            isFavorite: (_) => true,
                                            onToggleFavorite: (it) => ref.read(favoritesProvider.notifier).toggle(it.id),
                                            onRead: (it) =>
                                                _openDetailsPage(context, it),
                                            onDetails: (it) =>
                                                _showQuickDetails(context, it),
                                            onExternal: (it) =>
                                                _openExternal(context, it),
                                            onDownload: (it) =>
                                                _download(context, it),
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
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    8,
                                    12,
                                    6,
                                  ),
                                  sliver: SliverToBoxAdapter(
                                    child: _SectionHeader(
                                      title: 'Tous les films',
                                      count: otherItems.length,
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  sliver: listMode
                                      ? _MoviesSliverList(
                                          items: otherItems,
                                          isFavorite: (it) =>
                                              favIds.contains(it.id),
                                          onToggleFavorite: (it) => ref.read(favoritesProvider.notifier).toggle(it.id),
                                          onRead: (it) =>
                                              _openDetailsPage(context, it),
                                          onDetails: (it) =>
                                              _showQuickDetails(context, it),
                                          onExternal: (it) =>
                                              _openExternal(context, it),
                                          onDownload: (it) =>
                                              _download(context, it),
                                        )
                                      : _MoviesSliverMasonryGrid(
                                          items: otherItems,
                                          cross: cross,
                                          isFavorite: (it) =>
                                              favIds.contains(it.id),
                                          onToggleFavorite: (it) => ref.read(favoritesProvider.notifier).toggle(it.id),
                                          onRead: (it) =>
                                              _openDetailsPage(context, it),
                                          onDetails: (it) =>
                                              _showQuickDetails(context, it),
                                          onExternal: (it) =>
                                              _openExternal(context, it),
                                          onDownload: (it) =>
                                              _download(context, it),
                                        ),
                                ),
                                if (vmState.hasMore)
                                   const SliverToBoxAdapter(child: Center(child: Padding(
                                     padding: EdgeInsets.all(16.0),
                                     child: CircularProgressIndicator(),
                                   ))),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 12),
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          if (vmState.isLoading && vmState.items.isEmpty)
             const _PageLoading(),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: iptvState.isLoading
                ? const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : const SizedBox.shrink(),
          ),
        ]
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

  String _safeHost(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return '';
    }
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
  final bool Function(IptvItem) isFavorite;
  final void Function(IptvItem) onToggleFavorite;

  final void Function(IptvItem) onRead;
  final void Function(IptvItem) onDetails;
  final void Function(IptvItem) onExternal;
  final void Function(IptvItem) onDownload;

  const _MoviesSliverList({
    required this.items,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRead,
    required this.onDetails,
    required this.onExternal,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((ctx, i) {
        final it = items[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _MovieRowTile(
            item: it,
            favorite: isFavorite(it),
            onToggleFavorite: () => onToggleFavorite(it),
            onRead: () => onRead(it),
            onDetails: () => onDetails(it),
            onExternal: () => onExternal(it),
            onDownload: () => onDownload(it),
          ),
        );
      }, childCount: items.length),
    );
  }
}

class _MoviesSliverMasonryGrid extends StatelessWidget {
  final List<IptvItem> items;
  final int cross;
  final bool Function(IptvItem) isFavorite;
  final void Function(IptvItem) onToggleFavorite;

  final void Function(IptvItem) onRead;
  final void Function(IptvItem) onDetails;
  final void Function(IptvItem) onExternal;
  final void Function(IptvItem) onDownload;

  const _MoviesSliverMasonryGrid({
    required this.items,
    required this.cross,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRead,
    required this.onDetails,
    required this.onExternal,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return SliverMasonryGrid.count(
      crossAxisCount: cross,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childCount: items.length,
      itemBuilder: (ctx, i) {
        final it = items[i];
        return _MovieCardGrid(
          item: it,
          favorite: isFavorite(it),
          onToggleFavorite: () => onToggleFavorite(it),
          onRead: () => onRead(it),
          onDetails: () => onDetails(it),
          onExternal: () => onExternal(it),
          onDownload: () => onDownload(it),
        );
      },
    );
  }
}

class _MovieRowTile extends StatelessWidget {
  final IptvItem item;
  final bool favorite;

  final VoidCallback onToggleFavorite;
  final VoidCallback onRead;
  final VoidCallback onDetails;
  final VoidCallback onExternal;
  final VoidCallback onDownload;

  const _MovieRowTile({
    required this.item,
    required this.favorite,
    required this.onToggleFavorite,
    required this.onRead,
    required this.onDetails,
    required this.onExternal,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final poster = item.logo;

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
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.groupTitle ?? '',
                      softWrap: true,
                      overflow: TextOverflow.visible,
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
              IconButton(
                tooltip: favorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
                onPressed: onToggleFavorite,
                icon: Icon(favorite ? Icons.star : Icons.star_border),
                color: favorite ? Colors.amber : cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieCardGrid extends StatelessWidget {
  final IptvItem item;
  final bool favorite;

  final VoidCallback onToggleFavorite;
  final VoidCallback onRead;
  final VoidCallback onDetails;
  final VoidCallback onExternal;
  final VoidCallback onDownload;

  const _MovieCardGrid({
    required this.item,
    required this.favorite,
    required this.onToggleFavorite,
    required this.onRead,
    required this.onDetails,
    required this.onExternal,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final poster = item.logo;

    return InkWell(
      onTap: onRead,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
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
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  tooltip: favorite
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    favorite ? Icons.star : Icons.star_border,
                    size: 18,
                  ),
                  color: favorite ? Colors.amber : Colors.white,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: _GridActionsBar(
                    onRead: onRead,
                    onDetails: onDetails,
                    onExternal: onExternal,
                    onDownload: onDownload,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                if (item.groupTitle != null)
                  Text(
                    item.groupTitle ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GridActionsBar extends StatelessWidget {
  final VoidCallback onRead;
  final VoidCallback onDetails;
  final VoidCallback onExternal;
  final VoidCallback onDownload;

  const _GridActionsBar({
    required this.onRead,
    required this.onDetails,
    required this.onExternal,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _IconMini(icon: Icons.menu_book, tooltip: 'Lire', onTap: onRead),
        _IconMini(
          icon: Icons.info_outline,
          tooltip: 'Détails',
          onTap: onDetails,
        ),
        _IconMini(
          icon: Icons.open_in_new,
          tooltip: 'Ouvrir externe',
          onTap: onExternal,
        ),
        _IconMini(
          icon: Icons.download,
          tooltip: 'Télécharger',
          onTap: onDownload,
        ),
      ],
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _IconMini extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconMini({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      tooltip: tooltip,
      onPressed: onTap,
      iconSize: 20,
      icon: Icon(icon, color: Colors.white),
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
    return const Center(child: Text('Erreur de chargement'));
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onClear;
  const _EmptyState({this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Aucun film trouvé',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          if (onClear != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh),
              label: const Text('Effacer les filtres'),
            ),
          ],
        ],
      ),
    );
  }
}
