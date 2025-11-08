import 'package:flutter/material.dart';

class SeriesCard extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final int count;
  final VoidCallback onTap;

  const SeriesCard({
    required this.title,
    required this.posterUrl,
    required this.count,
    required this.onTap,
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
            AspectRatio(
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
