import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/settings_vm.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  late final TextEditingController segCtrl;
  late final TextEditingController partCtrl;
  late final TextEditingController maxCtrl;
  late final TextEditingController uaCtrl;
  late final TextEditingController refCtrl;
  late final TextEditingController dirCtrl;
  late final TextEditingController omdbCtrl;

  bool _saving = false;
  bool _obscureOmdb = true;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsVmProvider);
    segCtrl = TextEditingController(text: s.segmentsPerFile.toString());
    partCtrl = TextEditingController(
      text: (s.partSizeBytes / (1024 * 1024)).toStringAsFixed(0),
    );
    maxCtrl = TextEditingController(text: s.maxActiveFiles.toString());
    uaCtrl = TextEditingController(text: s.defaultUserAgent);
    refCtrl = TextEditingController(text: s.defaultReferer ?? '');
    dirCtrl = TextEditingController(text: s.downloadDir ?? '');
    omdbCtrl = TextEditingController(text: s.omdbApiKey ?? '');
  }

  @override
  void dispose() {
    segCtrl.dispose();
    partCtrl.dispose();
    maxCtrl.dispose();
    uaCtrl.dispose();
    refCtrl.dispose();
    dirCtrl.dispose();
    omdbCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(settingsVmProvider.notifier);

    return Scaffold(
      body: AbsorbPointer(
        absorbing: _saving,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _numField(segCtrl, 'Segments per file'),
            const SizedBox(height: 12),
            _numField(partCtrl, 'Part size MB'),
            const SizedBox(height: 12),
            _numField(maxCtrl, 'Max active files'),
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
                      hintText: '/Users/you/Downloads/Cnd',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    final picked = await FilePicker.platform.getDirectoryPath();
                    if (picked != null && picked.isNotEmpty) {
                      setState(() => dirCtrl.text = picked);
                    }
                  },
                  child: const Text('Browse'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: omdbCtrl,
              obscureText: _obscureOmdb,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'OMDb API Key',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscureOmdb = !_obscureOmdb),
                  icon: Icon(
                    _obscureOmdb ? Icons.visibility : Icons.visibility_off,
                  ),
                  tooltip: _obscureOmdb ? 'Show' : 'Hide',
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving
                  ? null
                  : () async {
                      FocusScope.of(context).unfocus();
                      setState(() => _saving = true);
                      try {
                        vm.setSegments(
                          int.tryParse(segCtrl.text) ??
                              ref.read(settingsVmProvider).segmentsPerFile,
                        );
                        vm.setPartSize(
                          (((double.tryParse(partCtrl.text) ??
                                      (ref
                                              .read(settingsVmProvider)
                                              .partSizeBytes /
                                          (1024 * 1024)))) *
                                  1024 *
                                  1024)
                              .toInt(),
                        );
                        vm.setMaxActive(
                          int.tryParse(maxCtrl.text) ??
                              ref.read(settingsVmProvider).maxActiveFiles,
                        );
                        vm.setUa(
                          uaCtrl.text.trim().isEmpty
                              ? ref.read(settingsVmProvider).defaultUserAgent
                              : uaCtrl.text.trim(),
                        );
                        vm.setReferer(
                          refCtrl.text.trim().isEmpty
                              ? null
                              : refCtrl.text.trim(),
                        );
                        vm.setDownloadDir(
                          dirCtrl.text.trim().isEmpty
                              ? null
                              : dirCtrl.text.trim(),
                        );
                        vm.setOmdbKey(
                          omdbCtrl.text.trim().isEmpty
                              ? null
                              : omdbCtrl.text.trim(),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings saved')),
                        );
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
    );
  }
}
