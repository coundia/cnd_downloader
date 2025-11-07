import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/download_models.dart';
import '../../viewmodels/download_list_vm.dart';

class DownloadTile extends StatelessWidget {
  final DownloadTask task;
  final DownloadListVm vm;
  const DownloadTile({super.key, required this.task, required this.vm});

  @override
  Widget build(BuildContext context) {
    final f = NumberFormat.compact();
    final p = task.total > 0 ? task.downloaded / task.total : 0.0;
    final eta = _fmtEta(task.etaSeconds);
    final sizeStr = '${_fmtBytes(task.downloaded)} / ${_fmtBytes(task.total)}';
    final speed = task.speedBps > 0 ? '${_fmtBytes(task.speedBps)}/s' : '';
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
            ].join(' • '),
          ),
        ],
      ),
      trailing: Wrap(
        spacing: 8,
        children: [
          if (task.state == 'running')
            IconButton(
              onPressed: () => vm.pause(task.id),
              icon: const Icon(Icons.pause),
            ),
          if (task.state == 'paused' ||
              task.state == 'queued' ||
              task.state == 'error')
            IconButton(
              onPressed: () => vm.start(task.id),
              icon: const Icon(Icons.play_arrow),
            ),
        ],
      ),
    );
  }

  String _fmtBytes(num b) {
    if (b <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double v = b.toDouble();
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(v >= 100
        ? 0
        : v >= 10
        ? 1
        : 2)} ${units[i]}';
  }

  String _fmtEta(int s) {
    if (s <= 0) return '';
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}';
    if (m > 0) return '${m}m${sec.toString().padLeft(2, '0')}s';
    return '${sec}s';
  }
}
