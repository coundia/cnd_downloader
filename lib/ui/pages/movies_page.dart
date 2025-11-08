import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/paths.dart';
import '../../viewmodels/download_list_vm.dart';
import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});
  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> {
  String q = '';
  IptvItem? selected;

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(moviesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search movies',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
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
          if (filtered.isEmpty) {
            return const Center(child: Text('No movie found'));
          }

          return LayoutBuilder(
            builder: (c, bc) {
              final wide = bc.maxWidth >= 1100;
              final left = wide ? bc.maxWidth - 380 : bc.maxWidth;
              final grid = _Grid(
                items: filtered,
                selected: selected,
                onSelect: (it) => setState(() => selected = it),
              );

              if (!wide) {
                return grid;
              }

              final sel = selected ?? filtered.first;
              return Row(
                children: [
                  SizedBox(width: left, child: grid),
                  const VerticalDivider(width: 1),
                  SizedBox(width: 380, child: MovieDetailsPane(item: sel)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  final List<IptvItem> items;
  final IptvItem? selected;
  final ValueChanged<IptvItem> onSelect;
  const _Grid({
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
          itemBuilder: (_, i) => _Poster(
            item: items[i],
            selected:
                identical(items[i], selected) ||
                (selected != null &&
                    items[i].name == selected!.name &&
                    items[i].streamUrl == selected!.streamUrl),
            onTap: () {
              final wide = MediaQuery.of(context).size.width >= 1100;
              if (wide) {
                onSelect(items[i]);
              } else {
                showModalBottomSheet(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (_) => DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.85,
                    minChildSize: 0.5,
                    maxChildSize: 0.95,
                    builder: (_, __) => MovieDetailsPane(item: items[i]),
                  ),
                );
              }
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
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected
        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
        : null;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: border?.top ?? BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class MovieDetailsPane extends ConsumerWidget {
  final IptvItem item;
  const MovieDetailsPane({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy URL',
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: item.streamUrl),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URL copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            const SizedBox(height: 8),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: (item.logo ?? '').isNotEmpty
                  ? Image.network(
                      item.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF111111)),
                    )
                  : const ColoredBox(color: Color(0xFF111111)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(text: item.groupTitle ?? 'Movie'),
                  _Chip(text: _hostOf(item.streamUrl)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                item.streamUrl,
                style: theme.textTheme.bodySmall,
                maxLines: 3,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        _openUrlExternally(item.streamUrl, context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Watch'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      String? dir = await defaultDownloadDir();
                      final vm = ref.read(listVmProvider.notifier);
                      await vm.addOnly(item.streamUrl, dir);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Queued to Downloads')),
                        );
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _hostOf(String url) {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _openUrlExternally(String url, BuildContext context) async {
    try {
      if (Platform.isMacOS) {
        await Process.run('/usr/bin/open', [url]);
      } else if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [url]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Open failed: $e')));
      }
    }
  }
}
