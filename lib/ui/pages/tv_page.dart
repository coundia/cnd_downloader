import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';

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
            onPressed: () => _openSources(context),
            icon: const Icon(Icons.playlist_play),
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
              if (filtered.isEmpty)
                return const Center(child: Text('Aucune chaîne'));
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
        onPressed: () => _openAddSource(context),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter source'),
      ),
    );
  }

  Future<void> _openAddSource(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddIptvSourceSheet(),
    );
  }

  Future<void> _openSources(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (c) {
        final sources = ref.watch(sourcesProvider);
        final vm = ref.read(iptvVmProvider.notifier);
        return SizedBox(
          height: 420,
          child: sources.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Erreur')),
            data: (list) => list.isEmpty
                ? const Center(child: Text('Aucune source'))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final s = list[i];
                      return ListTile(
                        title: Text(s.name),
                        subtitle: Text(
                          '${s.type.toUpperCase()} • ${s.url ?? s.server ?? ''}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              onPressed: () => vm.refresh(s.id),
                              icon: const Icon(Icons.refresh),
                            ),
                            IconButton(
                              onPressed: () => vm.remove(s.id),
                              icon: const Icon(Icons.delete_forever),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        );
      },
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

class _AddIptvSourceSheet extends ConsumerStatefulWidget {
  const _AddIptvSourceSheet({super.key});
  @override
  ConsumerState<_AddIptvSourceSheet> createState() =>
      _AddIptvSourceSheetState();
}

class _AddIptvSourceSheetState extends ConsumerState<_AddIptvSourceSheet>
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

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une source IPTV',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'Nom'),
                controller: nameCtrl,
              ),
              const SizedBox(height: 12),
              TabBar(
                controller: tab,
                tabs: const [
                  Tab(text: 'M3U'),
                  Tab(text: 'Xtream'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 160,
                child: TabBarView(
                  controller: tab,
                  children: [
                    Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'URL M3U',
                          ),
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
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const Spacer(),
                  FilledButton(
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
                                if (mounted) Navigator.pop(context);
                              }
                            } else {
                              final s = serverCtrl.text.trim();
                              final u = userCtrl.text.trim();
                              final p = passCtrl.text.trim();
                              if (s.isNotEmpty &&
                                  u.isNotEmpty &&
                                  p.isNotEmpty) {
                                await vm.addXtream(name, s, u, p);
                                if (mounted) Navigator.pop(context);
                              }
                            }
                          },
                    child: const Text('Ajouter'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
