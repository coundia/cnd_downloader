import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/iptv_models.dart';
import '../../../viewmodels/iptv_vm.dart';
import 'movies/movie_details_page.dart';
import 'movies/widgets/movie_grid.dart';
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

          final grid = MovieGrid(
            items: filtered,
            selected: null,
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
