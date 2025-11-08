import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/iptv_vm.dart';

class SourceFormPage extends ConsumerStatefulWidget {
  const SourceFormPage({super.key});
  @override
  ConsumerState<SourceFormPage> createState() => _SourceFormPageState();
}

class _SourceFormPageState extends ConsumerState<SourceFormPage>
    with SingleTickerProviderStateMixin {
  late final TabController tab = TabController(length: 2, vsync: this);
  final nameCtrl = TextEditingController();
  final m3uCtrl = TextEditingController();
  final serverCtrl = TextEditingController();
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  void dispose() {
    tab.dispose();
    nameCtrl.dispose();
    m3uCtrl.dispose();
    serverCtrl.dispose();
    userCtrl.dispose();
    passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.read(iptvVmProvider.notifier);
    final isLoading = ref.watch(iptvVmProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle source'),
        bottom: TabBar(
          controller: tab,
          tabs: const [
            Tab(text: 'M3U'),
            Tab(text: 'Xtream'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Nom'),
              controller: nameCtrl,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 190,
              child: TabBarView(
                controller: tab,
                children: [
                  Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(labelText: 'URL M3U'),
                        controller: m3uCtrl,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Serveur (ex: http://host:port)',
                        ),
                        controller: serverCtrl,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                        controller: userCtrl,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        controller: passCtrl,
                        obscureText: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                OutlinedButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim().isEmpty
                              ? 'Source'
                              : nameCtrl.text.trim();
                          if (tab.index == 0) {
                            final url = m3uCtrl.text.trim();
                            if (url.startsWith('http')) {
                              await vm.addM3u(name, url);
                              if (mounted) Navigator.pop(context, true);
                            }
                          } else {
                            final s = serverCtrl.text.trim();
                            final u = userCtrl.text.trim();
                            final p = passCtrl.text.trim();
                            if (s.isNotEmpty && u.isNotEmpty && p.isNotEmpty) {
                              await vm.addXtream(name, s, u, p);
                              if (mounted) Navigator.pop(context, true);
                            }
                          }
                        },
                  label: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
