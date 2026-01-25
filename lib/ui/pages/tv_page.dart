// lib/pages/tv_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/iptv_models.dart';
import '../../core/settings.dart';
import '../../services/open_external.dart';
import '../../viewmodels/iptv_vm.dart';
import '../../state/favorites_store.dart';
import '../widgets/cnd_video_player.dart';

class TvPage extends ConsumerStatefulWidget {
  const TvPage({super.key});
  @override
  ConsumerState<TvPage> createState() => _TvPageState();
}

class _TvPageState extends ConsumerState<TvPage> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  String q = '';
  bool listMode = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(liveProvider);
    final vmState = ref.watch(iptvVmProvider);

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV'),
        actions: [
          IconButton(
            tooltip: 'Mode liste',
            isSelected: listMode,
            onPressed: () => setState(() => listMode = true),
            icon: const Icon(Icons.view_list),
          ),
          IconButton(
            tooltip: 'Mode grille',
            isSelected: !listMode,
            onPressed: () => setState(() => listMode = false),
            icon: const Icon(Icons.grid_view),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: 'Effacer la recherche',
            onPressed: q.isEmpty
                ? null
                : () {
                    _searchCtrl.clear();
                    setState(() => q = '');
                    _searchFocus.requestFocus();
                  },
            icon: const Icon(Icons.close),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(72),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: _SearchField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          items.when(
            loading: () => const _PageLoading(),
            error: (_, __) => const _PageError(),
            data: (list) {
              final filtered = q.isEmpty
                  ? list
                  : list
                        .where(
                          (e) => ('${e.name} ${e.groupTitle ?? ''}')
                              .toLowerCase()
                              .contains(q),
                        )
                        .toList();

              final favIds = ref.watch(favoritesProvider);
              final favItems = filtered
                  .where((e) => favIds.contains(e.id))
                  .toList();

              if (filtered.isEmpty) {
                return _EmptyState(
                  title: 'Aucune chaîne',
                  subtitle: q.isEmpty
                      ? 'Ajoutez une source IPTV ou vérifiez votre connexion.'
                      : 'Aucun résultat pour “${_searchCtrl.text.trim()}”.',
                  actionLabel: q.isEmpty ? null : 'Effacer',
                  onAction: q.isEmpty
                      ? null
                      : () {
                          _searchCtrl.clear();
                          setState(() => q = '');
                          _searchFocus.requestFocus();
                        },
                );
              }

              return LayoutBuilder(
                builder: (c, bc) {
                  final w = bc.maxWidth;
                  final cross = w >= 1600
                      ? 6
                      : w >= 1200
                      ? 5
                      : w >= 900
                      ? 4
                      : w >= 600
                      ? 3
                      : 2;

                  Widget favSliver() {
                    if (listMode) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final it = favItems[i];
                          final isFav = favIds.contains(it.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChannelCard(
                              item: it,
                              isFavorite: isFav,
                              compact: true,
                              onToggleFavorite: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(it.id),
                              onPlay: () => _openPlayer(it),
                              onCopy: () => _copyUrl(context, it),
                            ),
                          );
                        }, childCount: favItems.length),
                      );
                    }

                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final it = favItems[i];
                        final isFav = favIds.contains(it.id);
                        return _ChannelCard(
                          item: it,
                          isFavorite: isFav,
                          compact: w < 480,
                          onToggleFavorite: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(it.id),
                          onPlay: () => _openPlayer(it),
                          onCopy: () => _copyUrl(context, it),
                        );
                      }, childCount: favItems.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.8,
                      ),
                    );
                  }

                  Widget allSliver() {
                    if (listMode) {
                      return SliverList(
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final it = filtered[i];
                          final isFav = favIds.contains(it.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChannelCard(
                              item: it,
                              isFavorite: isFav,
                              compact: true,
                              onToggleFavorite: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(it.id),
                              onPlay: () => _openPlayer(it),
                              onCopy: () => _copyUrl(context, it),
                            ),
                          );
                        }, childCount: filtered.length),
                      );
                    }

                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final it = filtered[i];
                        final isFav = favIds.contains(it.id);
                        return _ChannelCard(
                          item: it,
                          isFavorite: isFav,
                          compact: w < 480,
                          onToggleFavorite: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(it.id),
                          onPlay: () => _openPlayer(it),
                          onCopy: () => _copyUrl(context, it),
                        );
                      }, childCount: filtered.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cross,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 2.8,
                      ),
                    );
                  }

                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _CountChip(
                                label: 'Chaînes',
                                value: filtered.length,
                                icon: Icons.live_tv,
                              ),
                              _CountChip(
                                label: 'Favoris',
                                value: favItems.length,
                                icon: Icons.star,
                              ),
                              if (q.isNotEmpty)
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.filter_alt,
                                    size: 18,
                                  ),
                                  label: Text('“${_searchCtrl.text.trim()}”'),
                                  onPressed: () => _searchFocus.requestFocus(),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (favItems.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                          sliver: SliverToBoxAdapter(
                            child: _SectionHeader(
                              title: 'Favoris',
                              trailing: Text(
                                '${favItems.length}',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          sliver: favSliver(),
                        ),
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(12, 12, 12, 6),
                            child: Divider(height: 1),
                          ),
                        ),
                      ],
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                        sliver: SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: 'Toutes les chaînes',
                            trailing: Text(
                              '${filtered.length}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: allSliver(),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ],
                  );
                },
              );
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: vmState.isLoading
                ? const Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(minHeight: 2),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Map<String, String> _headersFor(IptvItem it) {
    final map = <String, String>{};
    final ua = (it.userAgent ?? '').trim().isNotEmpty
        ? it.userAgent!.trim()
        : settings.defaultUserAgent.trim();
    if (ua.isNotEmpty) map['user-agent'] = ua;

    final refh = (it.referer ?? '').trim().isNotEmpty
        ? it.referer!.trim()
        : (settings.defaultReferer ?? '').trim();
    if (refh.isNotEmpty) map['referer'] = refh;

    final hj = (it.headersJson ?? '').trim();
    if (hj.isNotEmpty) {
      try {
        final m = Map<String, dynamic>.from(json.decode(hj) as Map);
        m.forEach((k, v) {
          final key = k.toString();
          final val = v?.toString() ?? '';
          if (val.isNotEmpty) map[key] = val;
        });
      } catch (_) {}
    }
    return map;
  }

  void _openPlayer(IptvItem it) {
    final url = (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl;
    final headers = _headersFor(it);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _LivePlayerPage(title: it.name, url: url, headers: headers),
      ),
    );
  }

  Future<void> _copyUrl(BuildContext context, IptvItem it) async {
    final url = (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl;
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copiée'),
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Rechercher chaînes',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
        filled: true,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          title,
          style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _CountChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final IptvItem item;
  final VoidCallback onPlay;
  final VoidCallback onCopy;

  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  final bool compact;

  const _ChannelCard({
    required this.item,
    required this.onPlay,
    required this.onCopy,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = (item.realUrl ?? '').isNotEmpty
        ? item.realUrl!
        : item.streamUrl;

    return InkWell(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 12),
          child: Row(
            children: [
              _Logo(logo: item.logo),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.groupTitle ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: isFavorite
                    ? 'Retirer des favoris'
                    : 'Ajouter aux favoris',
                onPressed: onToggleFavorite,
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                color: isFavorite ? Colors.amber : cs.onSurfaceVariant,
              ),
              IconButton(
                tooltip: 'Ouvrir externe',
                onPressed: () => ExternalPlayer.open(url),
                icon: Icon(Icons.open_in_new, color: cs.onSurfaceVariant),
              ),
              IconButton(
                tooltip: 'Copier l’URL',
                onPressed: onCopy,
                icon: Icon(Icons.link, color: cs.onSurfaceVariant),
              ),

              Icon(Icons.play_circle_fill, color: cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? logo;
  const _Logo({required this.logo});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasLogo = (logo ?? '').isNotEmpty;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: hasLogo
          ? Image.network(
              logo!,
              width: 34,
              height: 34,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.tv, color: cs.onSurfaceVariant),
            )
          : Icon(Icons.tv, color: cs.onSurfaceVariant),
    );
  }
}

class _PageLoading extends StatelessWidget {
  const _PageLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class _PageError extends StatelessWidget {
  const _PageError();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 42),
            const SizedBox(height: 10),
            Text(
              'Erreur de chargement',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Vérifiez la connexion ou la source IPTV.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 44),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.close),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePlayerPage extends StatelessWidget {
  final String title;
  final String url;
  final Map<String, String> headers;
  const _LivePlayerPage({
    required this.title,
    required this.url,
    required this.headers,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Copier l’URL',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('URL copiée'),
                  behavior: SnackBarBehavior.floating,
                  showCloseIcon: true,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CndVideoPlayer(
                    url: url,
                    headers: headers,
                    autoPlay: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
