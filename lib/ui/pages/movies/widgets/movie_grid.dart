import 'package:flutter/material.dart';
import '../../../../data/iptv_models.dart';
import 'movie_poster.dart';
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

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .68,
          ),
          itemCount: items.length,
          itemBuilder: (tileCtx, i) {
            final item = items[i];
            final isSel =
                identical(item, selected) ||
                (selected != null &&
                    item.name == selected!.name &&
                    item.streamUrl == selected!.streamUrl);

            return MoviePoster(
              item: item,
              selected: isSel,
              onTap: () {
                final wide = MediaQuery.of(tileCtx).size.width >= 1100;
                if (wide) {
                  onSelect(item);
                } else {
                  showModalBottomSheet(
                    context: tileCtx,
                    showDragHandle: true,
                    isScrollControlled: true,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(tileCtx).size.height * 0.95,
                    ),
                    builder: (sheetCtx) => MovieDetailsPane(item: item),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
