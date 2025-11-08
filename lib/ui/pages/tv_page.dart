import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';
import '../sources/sources_page.dart';
import '../sources/source_form_page.dart';

class TvPage extends ConsumerStatefulWidget {
  const TvPage({super.key});
  @override
  ConsumerState<TvPage> createState() => _TvPageState();
}

class _TvPageState extends ConsumerState<TvPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(liveProvider);
    final vmState = ref.watch(iptvVmProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TV'),
        actions: [
          IconButton(
            tooltip: 'Sources',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SourcesPage()),
            ),
            icon: const Icon(Icons.playlist_play),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'add') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SourceFormPage()),
                );
              } else if (v == 'sources') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SourcesPage()),
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'add', child: Text('Ajouter une source')),
              PopupMenuItem(value: 'sources', child: Text('Gérer les sources')),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher chaînes',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Erreur')),
            data: (list) {
              final filtered = q.isEmpty
                  ? list
                  : list
                        .where(
                          (e) => ('${e.name} ${e.groupTitle ?? ''}')
                              .toLowerCase()
                              .contains(q),
                        )
                        .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('Aucune chaîne'));
              }
              return LayoutBuilder(
                builder: (c, bc) {
                  final w = bc.maxWidth;
                  final cross = w >= 1600
                      ? 6
                      : w >= 1200
                      ? 5
                      : w >= 900
                      ? 4
                      : w >= 600
                      ? 3
                      : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (c, i) => _ChannelCard(item: filtered[i]),
                  );
                },
              );
            },
          ),
          vmState.isLoading
              ? const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(),
                )
              : const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SourceFormPage()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter source'),
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final IptvItem item;
  const _ChannelCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            if ((item.logo ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Image.network(
                  item.logo!,
                  width: 36,
                  height: 36,
                  errorBuilder: (_, __, ___) =>
                      const SizedBox(width: 36, height: 36),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    item.groupTitle ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.play_arrow),
          ],
        ),
      ),
    );
  }
}
