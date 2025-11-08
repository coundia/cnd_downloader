import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../viewmodels/iptv_vm.dart';
import '../../../data/iptv_models.dart';
import 'movies/widgets/movie_details_pane.dart';
import 'movies/widgets/movie_grid.dart';
import 'widgets/movie_grid.dart';
import 'widgets/movie_details_pane.dart';
import 'widgets/search_filter_bar.dart';

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});
  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> {
  String q = '';
  String? group;
  String? host;

  // Tri
  static const _sortKeys = <String>['Name', 'Group', 'Host'];
  String sortKey = _sortKeys.first;
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

          // Filtre
          final filtered = list.where((e) {
            final mQuery =
                q.isEmpty ||
                ('${e.name} ${e.groupTitle ?? ''}').toLowerCase().contains(
                  q.toLowerCase(),
                );
            final mGroup =
                group == null ||
                group!.isEmpty ||
                (e.groupTitle ?? 'Other') == group;
            final h = _safeHost(e.streamUrl);
            final mHost = host == null || host!.isEmpty || h == host;
            return mQuery && mGroup && mHost;
          }).toList();

          // Tri
          filtered.sort((a, b) {
            int res;
            switch (sortKey) {
              case 'Group':
                res = (a.groupTitle ?? 'Other').toLowerCase().compareTo(
                  (b.groupTitle ?? 'Other').toLowerCase(),
                );
                break;
              case 'Host':
                res = _safeHost(
                  a.streamUrl,
                ).toLowerCase().compareTo(_safeHost(b.streamUrl).toLowerCase());
                break;
              case 'Name':
              default:
                res = a.name.toLowerCase().compareTo(b.name.toLowerCase());
                break;
            }
            if (res == 0) {
              // Dénominateur commun pour stabilité
              res = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            }
            return sortAsc ? res : -res;
          });

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
                  sortKeys: _sortKeys,
                  selectedSortKey: sortKey,
                  onSelectSortKey: (v) => setState(
                    () => sortKey = (v == null || v.isEmpty)
                        ? _sortKeys.first
                        : v,
                  ),
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
              final detailsW = _clampDouble(bc.maxWidth * 0.34, 320, 480);

              final grid = MovieGrid(
                items: filtered,
                selected: selected,
                onSelect: (it) => setState(() => selected = it),
              );

              if (!wide) {
                // Stack mobile: barre en haut, grille en dessous
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
                      sortKeys: _sortKeys,
                      selectedSortKey: sortKey,
                      onSelectSortKey: (v) => setState(
                        () => sortKey = (v == null || v.isEmpty)
                            ? _sortKeys.first
                            : v,
                      ),
                      sortAsc: sortAsc,
                      onToggleAsc: () => setState(() => sortAsc = !sortAsc),
                    ),
                    const Divider(height: 1),
                    Expanded(child: grid),
                  ],
                );
              }

              // Large: grille à gauche, panneau détails à droite
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
                          sortKeys: _sortKeys,
                          selectedSortKey: sortKey,
                          onSelectSortKey: (v) => setState(
                            () => sortKey = (v == null || v.isEmpty)
                                ? _sortKeys.first
                                : v,
                          ),
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

  double _clampDouble(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}
