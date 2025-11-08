import 'package:flutter/material.dart';
import '../../../../data/iptv_models.dart';

class MovieGrid extends StatelessWidget {
  final List<IptvItem> items;
  final IptvItem? selected;
  final ValueChanged<IptvItem> onSelect;

  /// Must change when query/filter/sort changes to force a clean grid rebuild.
  final String identity;

  const MovieGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
    required this.identity,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (c, bc) {
        final w = bc.maxWidth;
        final cross = w >= 1800
            ? 8
            : w >= 1500
            ? 7
            : w >= 1200
            ? 6
            : w >= 900
            ? 5
            : w >= 650
            ? 4
            : 3;

        return GridView.builder(
          key: ValueKey(identity), // reset list safely when filters change
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .68,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i];
            // Stable unique key derived from content, not from index.
            final cellKey = ValueKey('${item.streamUrl}::${item.name}');
            final isSelected =
                selected != null &&
                (identical(item, selected) ||
                    (item.name == selected!.name &&
                        item.streamUrl == selected!.streamUrl));

            return _PosterCard(
              key: cellKey,
              item: item,
              selected: isSelected,
              onTap: () => onSelect(item),
            );
          },
        );
      },
    );
  }
}

class _PosterCard extends StatelessWidget {
  final IptvItem item;
  final bool selected;
  final VoidCallback onTap;

  const _PosterCard({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected ? BorderSide(color: primary, width: 2) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Fill available vertical space to avoid overflow during relayouts
            Expanded(
              child: (item.logo ?? '').isNotEmpty
                  ? Image.network(
                      item.logo!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFECECEC)),
                    )
                  : const ColoredBox(color: Color(0xFFECECEC)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Chip(text: item.groupTitle ?? 'Movie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;
  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
