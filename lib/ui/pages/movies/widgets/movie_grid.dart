import 'package:flutter/material.dart';
import '../../../../data/iptv_models.dart';
import 'movie_details_pane.dart';

class MovieGrid extends StatelessWidget {
  final List<IptvItem> items;
  final IptvItem? selected;
  final ValueChanged<IptvItem> onSelect;
  const MovieGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelect,
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

        return GridView.custom(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .68,
          ),
          childrenDelegate: SliverChildBuilderDelegate(
            (ctx, i) {
              final it = items[i];
              final isSel = selected?.streamUrl == it.streamUrl;
              return _Poster(
                key: ValueKey(it.streamUrl),
                item: it,
                selected: isSel,
                onTap: () {
                  final wide = MediaQuery.of(ctx).size.width >= 1100;
                  if (wide) {
                    onSelect(it);
                  } else {
                    showModalBottomSheet(
                      context: ctx,
                      showDragHandle: true,
                      isScrollControlled: true,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.95,
                      ),
                      builder: (_) => MovieDetailsPane(item: it),
                    );
                  }
                },
              );
            },
            childCount: items.length,
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            findChildIndexCallback: (Key key) {
              final k = key as ValueKey<String>;
              return items.indexWhere((e) => e.streamUrl == k.value);
            },
          ),
        );
      },
    );
  }
}

class _Poster extends StatelessWidget {
  final IptvItem item;
  final bool selected;
  final VoidCallback onTap;
  const _Poster({
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
          children: [
            Expanded(
              child: (item.logo ?? '').isNotEmpty
                  ? Image.network(
                      item.logo!,
                      fit: BoxFit.cover,
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
