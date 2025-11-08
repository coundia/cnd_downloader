import 'package:flutter/material.dart';

class SearchFilterBar extends StatelessWidget {
  final String query;
  final ValueChanged<String> onQuery;

  final List<String> groups;
  final String? selectedGroup;
  final ValueChanged<String?> onSelectGroup;

  final List<String> hosts;
  final String? selectedHost;
  final ValueChanged<String?> onSelectHost;

  // Tri
  final List<String> sortKeys;
  final String selectedSortKey;
  final ValueChanged<String?> onSelectSortKey;
  final bool sortAsc;
  final VoidCallback onToggleAsc;

  const SearchFilterBar({
    super.key,
    required this.query,
    required this.onQuery,
    required this.groups,
    required this.selectedGroup,
    required this.onSelectGroup,
    required this.hosts,
    required this.selectedHost,
    required this.onSelectHost,
    required this.sortKeys,
    required this.selectedSortKey,
    required this.onSelectSortKey,
    required this.sortAsc,
    required this.onToggleAsc,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final queryField = Expanded(
      flex: 2,
      child: TextField(
        onChanged: onQuery,
        controller: TextEditingController(text: query),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search movies',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );

    final groupField = Expanded(
      child: DropdownButtonFormField<String>(
        value: _normalizeChoice(groups, selectedGroup),
        isDense: true,
        items: groups
            .map(
              (g) => DropdownMenuItem(
                value: g,
                child: Text(
                  g.isEmpty ? 'All groups' : g,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onSelectGroup,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Group',
          isDense: true,
        ),
      ),
    );

    final hostField = Expanded(
      child: DropdownButtonFormField<String>(
        value: _normalizeChoice(hosts, selectedHost),
        isDense: true,
        items: hosts
            .map(
              (h) => DropdownMenuItem(
                value: h,
                child: Text(
                  h.isEmpty ? 'All hosts' : h,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: onSelectHost,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Host',
          isDense: true,
        ),
      ),
    );

    final sortField = Expanded(
      child: DropdownButtonFormField<String>(
        value: _normalizeChoice(sortKeys, selectedSortKey) ?? sortKeys.first,
        isDense: true,
        items: sortKeys
            .map(
              (k) => DropdownMenuItem(
                value: k,
                child: Text(k, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: onSelectSortKey,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          hintText: 'Sort by',
          isDense: true,
        ),
      ),
    );

    final sortOrderBtn = Tooltip(
      message: sortAsc ? 'Ascending' : 'Descending',
      child: InkWell(
        onTap: onToggleAsc,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(sortAsc ? Icons.arrow_upward : Icons.arrow_downward),
        ),
      ),
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: LayoutBuilder(
          builder: (c, bc) {
            // 0..719: 2 lignes
            // 720..999: 1 ligne compacte
            // 1000+: 1 ligne confortable
            final narrow = bc.maxWidth < 720;
            final comfy = bc.maxWidth >= 1000;

            if (narrow) {
              return Column(
                children: [
                  queryField,
                  const SizedBox(height: 8),
                  Row(
                    children: [groupField, const SizedBox(width: 8), hostField],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      sortField,
                      const SizedBox(width: 8),
                      SizedBox(width: 48, child: Center(child: sortOrderBtn)),
                    ],
                  ),
                ],
              );
            }

            // Large: tout sur une seule rangée
            return Row(
              children: [
                queryField,
                SizedBox(width: comfy ? 12 : 8),
                groupField,
                const SizedBox(width: 8),
                hostField,
                const SizedBox(width: 8),
                sortField,
                const SizedBox(width: 8),
                sortOrderBtn,
              ],
            );
          },
        ),
      ),
    );
  }

  String? _normalizeChoice(List<String> options, String? value) {
    if (value == null) return '';
    if (!options.contains(value)) return '';
    return value;
    // '' = "All ..."
  }
}
