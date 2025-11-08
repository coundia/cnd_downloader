import 'package:flutter/material.dart';

class SeriesCard extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final int count;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const SeriesCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.count,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: (posterUrl ?? '').isNotEmpty
                          ? Image.network(
                              posterUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const ColoredBox(color: Color(0xFFEEEEEE)),
                            )
                          : const ColoredBox(color: Color(0xFFEEEEEE)),
                    ),
                  ),
                  if (onToggleFavorite != null)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.35),
                        ),
                        onPressed: onToggleFavorite,
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                          size: 20,
                        ),
                        tooltip: isFavorite
                            ? 'Retirer des favoris'
                            : 'Ajouter aux favoris',
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('$count'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
