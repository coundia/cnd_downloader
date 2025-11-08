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
              final detailsW = _clampDouble(bc.maxWidth * 0.34, 320, 480);
              final grid = _Grid(
                items: filtered,
                selected: selected,
                onSelect: (it) => setState(() => selected = it),
              );

              if (!wide) return grid;

              final sel = selected ?? filtered.first;
              return Row(
                children: [
                  // Grid takes the remaining width
                  SizedBox(width: bc.maxWidth - detailsW - 1, child: grid),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: detailsW,
                    child: MovieDetailsPane(item: sel),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  double _clampDouble(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
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
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.95,
                  ),
                  builder: (_) => MovieDetailsPane(item: items[i]),
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

class MovieDetailsPane extends ConsumerWidget {
  final IptvItem item;
  const MovieDetailsPane({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (c, bc) {
            return Scrollbar(
              thumbVisibility: true,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 3,
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SelectableText(
                        item.streamUrl,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ActionsBar(streamUrl: item.streamUrl),
                ],
              ),
            );
          },
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
}

class _ActionsBar extends ConsumerWidget {
  final String streamUrl;
  const _ActionsBar({required this.streamUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (c, bc) {
        final narrow = bc.maxWidth < 360;
        final children = [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _openUrlExternally(streamUrl, context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Watch'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final dir = await defaultDownloadDir();
                await ref.read(listVmProvider.notifier).addOnly(streamUrl, dir);
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
        ];

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              children[0],
              const SizedBox(height: 10),
              children[2], // OutlinedButton wrapped
            ],
          );
        }
        return Row(children: children);
      },
    );
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
