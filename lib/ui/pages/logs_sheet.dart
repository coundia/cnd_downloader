import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/download_models.dart';
import '../../viewmodels/download_list_vm.dart';

class LogsSheet extends ConsumerWidget {
  final int taskId;
  const LogsSheet({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(repositoryProvider);
    return SizedBox(
      height: 420,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Text(
                  'Logs #$taskId',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Copy all',
                  onPressed: () async {
                    final logs = await repo.watchLogs(taskId).first;
                    final text = logs
                        .map(
                          (l) =>
                              '[${l.ts.toIso8601String()}] ${l.level.toUpperCase()}  ${l.message}',
                        )
                        .join('\n');
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied')),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_all),
                ),
                IconButton(
                  tooltip: 'Clear',
                  onPressed: () async {
                    await repo.clearLogs(taskId);
                  },
                  icon: const Icon(Icons.clear_all),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<DownloadLog>>(
              stream: repo.watchLogs(taskId),
              builder: (c, snap) {
                final logs = snap.data ?? const <DownloadLog>[];
                if (logs.isEmpty) return const Center(child: Text('No logs'));
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final l = logs[i];
                    final ts = l.ts.toIso8601String();
                    return SelectableText(
                      '[$ts] ${l.level.toUpperCase()}  ${l.message}',
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
