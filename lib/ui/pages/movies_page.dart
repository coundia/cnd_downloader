import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/iptv_models.dart';
import '../../../viewmodels/iptv_vm.dart';
import 'movies/movie_details_page.dart';
import 'movies/widgets/movie_details_pane.dart';
import 'movies/widgets/movie_grid.dart';
import 'widgets/search_filter_bar.dart';
import 'widgets/movie_grid.dart';
import 'widgets/movie_details_pane.dart';

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});
  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> {
  String q = '';
  String? group;
  String? host;
  String sortKey = 'Name';
  bool sortAsc = true;
  IptvItem? selected;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(moviesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Movies')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
        data: (list) {
          final allGroups = _uniqueGroups(list);
          final allHosts = _uniqueHosts(list);

          final filtered = list.where((e) {
            final hitQuery =
                q.isEmpty ||
                ('${e.name} ${e.groupTitle ?? ''}').toLowerCase().contains(
                  q.toLowerCase(),
                );
            final hitGroup =
                group == null ||
                group!.isEmpty ||
                (e.groupTitle ?? 'Other') == group;
            final h = _safeHost(e.streamUrl);
            final hitHost = host == null || host!.isEmpty || h == host;
            return hitQuery && hitGroup && hitHost;
          }).toList();

          _sortInPlace(filtered, sortKey, sortAsc);

          if (filtered.isEmpty) {
            return Column(
              children: [
                SearchFilterBar(
                  query: q,
                  onQuery: (v) => setState(() => q = v),
                  groups: allGroups,
                  selectedGroup: group,
                  onSelectGroup: (v) => setState(() => group = v),
                  hosts: allHosts,
                  selectedHost: host,
                  onSelectHost: (v) => setState(() => host = v),
                  sortKeys: const ['Name', 'Group', 'Host'],
                  selectedSortKey: sortKey,
                  onSelectSortKey: (v) => setState(() => sortKey = v ?? 'Name'),
                  sortAsc: sortAsc,
                  onToggleAsc: () => setState(() => sortAsc = !sortAsc),
                ),
                const Divider(height: 1),
                const Expanded(child: Center(child: Text('No movie found'))),
              ],
            );
          }

          return LayoutBuilder(
            builder: (c, bc) {
              final wide = bc.maxWidth >= 1100;
              final detailsW = _clamp(bc.maxWidth * 0.34, 320, 480);

              void onPick(IptvItem it) {
                if (wide) {
                  setState(() => selected = it);
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MovieDetailsPage(item: it),
                    ),
                  );
                }
              }

              final grid = MovieGrid(
                items: filtered,
                selected: selected,
                onSelect: onPick,
              );

              if (!wide) {
                return Column(
                  children: [
                    SearchFilterBar(
                      query: q,
                      onQuery: (v) => setState(() => q = v),
                      groups: allGroups,
                      selectedGroup: group,
                      onSelectGroup: (v) => setState(() => group = v),
                      hosts: allHosts,
                      selectedHost: host,
                      onSelectHost: (v) => setState(() => host = v),
                      sortKeys: const ['Name', 'Group', 'Host'],
                      selectedSortKey: sortKey,
                      onSelectSortKey: (v) =>
                          setState(() => sortKey = v ?? 'Name'),
                      sortAsc: sortAsc,
                      onToggleAsc: () => setState(() => sortAsc = !sortAsc),
                    ),
                    const Divider(height: 1),
                    Expanded(child: grid),
                  ],
                );
              }

              final sel = selected ?? filtered.first;
              return Row(
                children: [
                  SizedBox(
                    width: bc.maxWidth - detailsW - 1,
                    child: Column(
                      children: [
                        SearchFilterBar(
                          query: q,
                          onQuery: (v) => setState(() => q = v),
                          groups: allGroups,
                          selectedGroup: group,
                          onSelectGroup: (v) => setState(() => group = v),
                          hosts: allHosts,
                          selectedHost: host,
                          onSelectHost: (v) => setState(() => host = v),
                          sortKeys: const ['Name', 'Group', 'Host'],
                          selectedSortKey: sortKey,
                          onSelectSortKey: (v) =>
                              setState(() => sortKey = v ?? 'Name'),
                          sortAsc: sortAsc,
                          onToggleAsc: () => setState(() => sortAsc = !sortAsc),
                        ),
                        const Divider(height: 1),
                        Expanded(child: grid),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: detailsW,
                    child: MovieDetailsPane(item: sel),
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

  double _clamp(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}
