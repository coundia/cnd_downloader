import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/download_models.dart';
import '../../viewmodels/download_list_vm.dart';
import '../widgets/download_tile.dart';
import 'settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadListProvider).value ?? <DownloadTask>[];
    final vm = ref.watch(listVmProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: const Text('FastDown'),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('No downloads'))
          : ListView.separated(
              itemCount: tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (c, i) => DownloadTile(task: tasks[i], vm: vm),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final url = await _askUrl(context);
          if (url == null || url.isEmpty) return;
          final dir = await FilePicker.platform.getDirectoryPath();
          if (dir == null) return;
          await vm.addAndStart(url, dir);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<String?> _askUrl(BuildContext context) async {
    final ctrl = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
