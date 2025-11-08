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
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: LayoutBuilder(
          builder: (c, bc) {
            final narrow = bc.maxWidth < 720;
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

            if (narrow) {
              return Column(
                children: [
                  queryField,
                  const SizedBox(height: 8),
                  Row(
                    children: [groupField, const SizedBox(width: 8), hostField],
                  ),
                ],
              );
            }

            return Row(
              children: [
                queryField,
                const SizedBox(width: 12),
                groupField,
                const SizedBox(width: 8),
                hostField,
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
  }
}
