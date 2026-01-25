import 'package:flutter/material.dart';

class SeriesCardActions {
  final VoidCallback onRead;
  final VoidCallback onDetails;
  final VoidCallback onExternal;
  final VoidCallback onDownload;

  const SeriesCardActions({
    required this.onRead,
    required this.onDetails,
    required this.onExternal,
    required this.onDownload,
  });
}

class SeriesCard extends StatelessWidget {
  final String title;
  final String? posterUrl;
  final int count;

  final VoidCallback onTap;

  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  final SeriesCardActions? actions;

  const SeriesCard({
    super.key,
    required this.title,
    required this.posterUrl,
    required this.count,
    required this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final badgeColor = cs.surfaceContainerHighest;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if ((posterUrl ?? '').isNotEmpty)
                    Image.network(
                      posterUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFEEEEEE)),
                    )
                  else
                    const ColoredBox(color: Color(0xFFEEEEEE)),

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

                  if (actions != null)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: _ActionsBar(actions: actions!),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class _ActionsBar extends StatelessWidget {
  final SeriesCardActions actions;

  const _ActionsBar({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.48),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _IconMini(
              icon: Icons.menu_book,
              tooltip: 'Lire',
              onTap: actions.onRead,
            ),
            _IconMini(
              icon: Icons.info_outline,
              tooltip: 'Détails',
              onTap: actions.onDetails,
            ),
            _IconMini(
              icon: Icons.open_in_new,
              tooltip: 'Externe',
              onTap: actions.onExternal,
            ),
            _IconMini(
              icon: Icons.download,
              tooltip: 'Télécharger',
              onTap: actions.onDownload,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconMini extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _IconMini({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: Colors.white),
    );
  }
}
