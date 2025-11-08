import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'movies_filter_state.dart';
import 'movies_selectors.dart';

class MoviesFilterBar extends ConsumerWidget {
  MoviesFilterBar({super.key});

  final _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(movieGroupsProvider);
    final hosts = ref.watch(movieHostsProvider);
    final state = ref.watch(moviesFilterProvider);
    final vm = ref.read(moviesFilterProvider.notifier);

    if (_searchCtrl.text.toLowerCase() != state.query) {
      _searchCtrl.text = state.query;
      _searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchCtrl.text.length),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: LayoutBuilder(
        builder: (c, bc) {
          final vertical = bc.maxWidth < 800;
          final row = Row(
            children: [
              Flexible(
                flex: 2,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: vm.setQuery,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButtonFormField<String>(
                  value: state.group,
                  items: groups
                      .map(
                        (g) =>
                            DropdownMenuItem<String>(value: g, child: Text(g)),
                      )
                      .toList(),
                  onChanged: (v) => vm.setGroup(v ?? 'All'),
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Group',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: DropdownButtonFormField<String>(
                  value: state.host,
                  items: hosts
                      .map(
                        (h) =>
                            DropdownMenuItem<String>(value: h, child: Text(h)),
                      )
                      .toList(),
                  onChanged: (v) => vm.setHost(v ?? 'All'),
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Host',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('With poster'),
                selected: state.onlyWithLogo,
                onSelected: vm.toggleLogo,
              ),
              const SizedBox(width: 8),
              _SortButton(current: state.sort, onPick: vm.setSort),
            ],
          );

          if (!vertical) return row;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              row.children[0] as Widget,
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: row.children[2] as Widget),
                  const SizedBox(width: 8),
                  Expanded(child: row.children[4] as Widget),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  row.children[6] as Widget,
                  const SizedBox(width: 8),
                  row.children[8] as Widget,
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final MoviesSort current;
  final ValueChanged<MoviesSort> onPick;
  const _SortButton({required this.current, required this.onPick});

  String _label(MoviesSort s) {
    switch (s) {
      case MoviesSort.nameAsc:
        return 'Name ↑';
      case MoviesSort.nameDesc:
        return 'Name ↓';
      case MoviesSort.groupAsc:
        return 'Group';
      case MoviesSort.hostAsc:
        return 'Host';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MoviesSort>(
      initialValue: current,
      onSelected: onPick,
      itemBuilder: (_) => const [
        PopupMenuItem(value: MoviesSort.nameAsc, child: Text('Name ↑')),
        PopupMenuItem(value: MoviesSort.nameDesc, child: Text('Name ↓')),
        PopupMenuItem(value: MoviesSort.groupAsc, child: Text('Group')),
        PopupMenuItem(value: MoviesSort.hostAsc, child: Text('Host')),
      ],
      child: InputDecorator(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          labelText: 'Sort',
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_label(current)),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
