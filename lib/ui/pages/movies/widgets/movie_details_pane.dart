import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/paths.dart';
import '../../../../viewmodels/download_list_vm.dart';
import '../../../../data/iptv_models.dart';

class MovieDetailsPane extends ConsumerWidget {
  final IptvItem item;
  const MovieDetailsPane({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Scrollbar(
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
                    _Chip(text: _host(item.streamUrl)),
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
        ),
      ),
    );
  }

  String _host(String url) {
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

        final watchBtn = Expanded(
          child: FilledButton.icon(
            onPressed: () => _openUrlExternally(streamUrl, context),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Watch'),
          ),
        );

        final downloadBtn = Expanded(
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
        );

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [watchBtn, const SizedBox(height: 10), downloadBtn],
          );
        }
        return Row(
          children: [watchBtn, const SizedBox(width: 10), downloadBtn],
        );
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
