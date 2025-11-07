import 'package:flutter/material.dart';
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
              return Text('[$ts] ${l.level.toUpperCase()}  ${l.message}');
            },
          );
        },
      ),
    );
  }
}
