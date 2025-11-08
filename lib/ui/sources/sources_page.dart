import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';
import 'source_form_page.dart';

class SourcesPage extends ConsumerStatefulWidget {
  const SourcesPage({super.key});
  @override
  ConsumerState<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends ConsumerState<SourcesPage> {
  String q = '';
  String type = '';

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourcesProvider);
    final vm = ref.read(iptvVmProvider.notifier);
    final isLoading = ref.watch(iptvVmProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sources IPTV'),
        actions: [
          IconButton(
            onPressed: isLoading
                ? null
                : () async {
                    final list = await ref.read(sourcesProvider.future);
                    for (final s in list) {
                      await vm.refresh(s.id);
                    }
                  },
            icon: const Icon(Icons.refresh),
            tooltip: 'Tout actualiser',
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SourceFormPage()),
            ),
            icon: const Icon(Icons.add),
            tooltip: 'Ajouter',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) =>
                        setState(() => q = v.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Rechercher par nom/URL',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: type.isEmpty ? null : type,
                  hint: const Text('Type'),
                  items: const [
                    DropdownMenuItem(value: 'm3u', child: Text('M3U')),
                    DropdownMenuItem(value: 'xtream', child: Text('Xtream')),
                  ],
                  onChanged: (v) => setState(() => type = v ?? ''),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          sources.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Erreur')),
            data: (list) {
              final filtered =
                  list.where((s) => type.isEmpty ? true : s.type == type).where(
                      (s) {
                        if (q.isEmpty) return true;
                        final t = q;
                        final a = s.name.toLowerCase();
                        final b = (s.url ?? s.server ?? '').toLowerCase();
                        return a.contains(t) || b.contains(t);
                      },
                    ).toList()
                    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

              if (filtered.isEmpty) {
                return const Center(child: Text('Aucune source'));
              }

              return RefreshIndicator(
                onRefresh: () async {
                  for (final s in filtered) {
                    await vm.refresh(s.id);
                  }
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final s = filtered[i];
                    final rawUri = (s.url ?? s.server ?? '').trim();
                    final subtitle = '${s.type.toUpperCase()} • $rawUri';

                    return Card(
                      child: ListTile(
                        onLongPress: rawUri.isEmpty
                            ? null
                            : () => _copyUri(context, rawUri),
                        title: Text(
                          s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        leading: const Icon(Icons.storage),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            IconButton(
                              tooltip: 'Copier l’URL',
                              onPressed: rawUri.isEmpty
                                  ? null
                                  : () => _copyUri(context, rawUri),
                              icon: const Icon(Icons.content_copy),
                            ),
                            IconButton(
                              tooltip: 'Actualiser',
                              onPressed: isLoading
                                  ? null
                                  : () => vm.refresh(s.id),
                              icon: const Icon(Icons.refresh),
                            ),
                            IconButton(
                              tooltip: 'Supprimer',
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      final ok =
                                          await showDialog<bool>(
                                            context: context,
                                            builder: (_) => AlertDialog(
                                              title: const Text('Supprimer ?'),
                                              content: Text(
                                                'Supprimer "${s.name}"',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Annuler'),
                                                ),
                                                FilledButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text(
                                                    'Supprimer',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ) ??
                                          false;
                                      if (ok) await vm.remove(s.id);
                                    },
                              icon: const Icon(Icons.delete_forever),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          isLoading
              ? const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Future<void> _copyUri(BuildContext context, String uri) async {
    await Clipboard.setData(ClipboardData(text: uri));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('URL copiée')));
  }
}
