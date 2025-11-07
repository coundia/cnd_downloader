import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/paths.dart';
import '../../data/download_models.dart';
import '../../viewmodels/download_list_vm.dart';
import 'settings_page.dart';
import 'logs_sheet.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<void>>(listVmProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e'))),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('FastDown'),
        actions: [
          IconButton(
            tooltip: 'Quick add',
            onPressed: () async {
              final dir = await defaultDownloadDir();
              await ref
                  .read(listVmProvider.notifier)
                  .addOnly('https://speed.hetzner.de/10MB.bin', dir);
            },
            icon: const Icon(Icons.add_to_queue),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: ref
          .watch(downloadListProvider)
          .when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading')),
            data: (tasks) => tasks.isEmpty
                ? const Center(child: Text('No downloads'))
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (c, i) => _DownloadTile(task: tasks[i]),
                  ),
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final urls = await _askUrls(context);
          if (urls == null || urls.isEmpty) return;
          String? dir = await FilePicker.platform.getDirectoryPath();
          dir ??= await defaultDownloadDir();
          final vm = ref.read(listVmProvider.notifier);
          for (final u in urls) {
            await vm.addOnly(u, dir);
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Queued ${urls.length} link(s) → $dir')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<String>?> _askUrls(BuildContext context) async {
    final ctrl = TextEditingController();
    return await showDialog<List<String>>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add URLs'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: ctrl,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'One URL per line (http or https)',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final lines = ctrl.text
                  .split('\n')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .where(
                    (s) => s.startsWith('http://') || s.startsWith('https://'),
                  )
                  .toList();
              Navigator.pop(c, lines);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _DownloadTile extends ConsumerWidget {
  final DownloadTask task;
  const _DownloadTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(listVmProvider.notifier);
    final p = task.total > 0 ? task.downloaded / task.total : 0.0;
    final sizeStr = '${_fmtBytes(task.downloaded)} / ${_fmtBytes(task.total)}';
    final speed = task.speedBps > 0 ? '${_fmtBytes(task.speedBps)}/s' : '';
    final eta = _fmtEta(task.etaSeconds);

    return ListTile(
      title: Text(task.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(value: p),
          const SizedBox(height: 6),
          Text(
            [
              sizeStr,
              if (speed.isNotEmpty) speed,
              if (eta.isNotEmpty) 'ETA $eta',
              task.state,
            ].join(' • '),
          ),
        ],
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          IconButton(
            tooltip: 'Logs',
            onPressed: () => showModalBottomSheet(
              context: context,
              showDragHandle: true,
              builder: (_) => LogsSheet(taskId: task.id),
            ),
            icon: const Icon(Icons.article),
          ),
          if (task.state == 'running')
            IconButton(
              onPressed: () => vm.pause(task.id),
              icon: const Icon(Icons.pause),
            ),
          if (task.state == 'paused' || task.state == 'queued')
            IconButton(
              onPressed: () => vm.start(task.id),
              icon: const Icon(Icons.play_arrow),
            ),
          if (task.state == 'error')
            IconButton(
              onPressed: () => vm.retry(task.id),
              icon: const Icon(Icons.refresh),
            ),
          IconButton(
            onPressed: () => vm.delete(task.id),
            icon: const Icon(Icons.delete_forever),
          ),

          if (task.state == 'completed')
            IconButton(
              onPressed: () => vm.open(task.id),
              icon: const Icon(Icons.open_in_new),
            ),
          IconButton(
            onPressed: () => vm.reveal(task.id),
            icon: const Icon(Icons.folder_open),
          ),
          IconButton(
            onPressed: () => vm.verify(task.id),
            icon: const Icon(Icons.check_circle),
          ),
        ],
      ),
    );
  }

  String _fmtBytes(num b) {
    if (b <= 0) return '0 B';
    const u = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double v = b.toDouble();
    while (v >= 1024 && i < u.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(v >= 100
        ? 0
        : v >= 10
        ? 1
        : 2)} ${u[i]}';
  }

  String _fmtEta(int s) {
    if (s <= 0) return '';
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    if (m > 0) return '${m}m${sec.toString().padLeft(2, '0')}s';
    return '${sec}s';
  }
}
