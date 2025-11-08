import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/iptv_vm.dart';
import '../../data/iptv_models.dart';

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});
  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final items = ref.watch(moviesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher films',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ),
      ),
      body: items.when(
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
          if (filtered.isEmpty) return const Center(child: Text('Aucun film'));
          return _grid(filtered);
        },
      ),
    );
  }

  Widget _grid(List<IptvItem> items) {
    return LayoutBuilder(
      builder: (c, bc) {
        final w = bc.maxWidth;
        final cross = w >= 1600
            ? 7
            : w >= 1200
            ? 6
            : w >= 900
            ? 5
            : w >= 600
            ? 4
            : 3;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: .7,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => _Poster(item: items[i]),
        );
      },
    );
  }
}

class _Poster extends StatelessWidget {
  final IptvItem item;
  const _Poster({required this.item});
  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {},
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 2 / 3,
              child: (item.logo ?? '').isNotEmpty
                  ? Image.network(
                      item.logo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFFEEEEEE)),
                    )
                  : const ColoredBox(color: Color(0xFFEEEEEE)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
