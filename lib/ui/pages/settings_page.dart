import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/settings_vm.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsVmProvider);
    final vm = ref.read(settingsVmProvider.notifier);

    final segCtrl = TextEditingController(text: s.segmentsPerFile.toString());
    final partCtrl = TextEditingController(
      text: (s.partSizeBytes / (1024 * 1024)).toStringAsFixed(0),
    );
    final maxCtrl = TextEditingController(text: s.maxActiveFiles.toString());
    final uaCtrl = TextEditingController(text: s.defaultUserAgent);
    final refCtrl = TextEditingController(text: s.defaultReferer ?? '');
    final dirCtrl = TextEditingController(text: s.downloadDir ?? '');

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: segCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Segments per file'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: partCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Part size MB'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: maxCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Max active files'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: uaCtrl,
            decoration: const InputDecoration(labelText: 'User-Agent'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: refCtrl,
            decoration: const InputDecoration(labelText: 'Referer'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: dirCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Download directory',
                    hintText: '/Users/you/Downloads/FastDown',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () async {
                  final picked = await FilePicker.platform.getDirectoryPath();
                  if (picked != null && picked.isNotEmpty) {
                    dirCtrl.text = picked;
                  }
                },
                child: const Text('Parcourir'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              vm.setSegments(int.tryParse(segCtrl.text) ?? s.segmentsPerFile);
              vm.setPartSize(
                ((double.tryParse(partCtrl.text) ??
                            (s.partSizeBytes / (1024 * 1024))) *
                        1024 *
                        1024)
                    .toInt(),
              );
              vm.setMaxActive(int.tryParse(maxCtrl.text) ?? s.maxActiveFiles);
              vm.setUa(
                uaCtrl.text.trim().isEmpty
                    ? s.defaultUserAgent
                    : uaCtrl.text.trim(),
              );
              vm.setReferer(
                refCtrl.text.trim().isEmpty ? null : refCtrl.text.trim(),
              );
              vm.setDownloadDir(
                dirCtrl.text.trim().isEmpty ? null : dirCtrl.text.trim(),
              );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
