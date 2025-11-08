import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/iptv_models.dart';
import '../../../viewmodels/iptv_vm.dart';
import 'filters/movies_filter_state.dart';
import 'filters/movies_filter_bar.dart';
import 'filters/movies_selectors.dart';
import 'movies/widgets/movie_details_pane.dart';
import 'movies/widgets/movie_grid.dart';
import 'widgets/movie_details_pane.dart';
import 'widgets/movie_grid.dart';

class MoviesPage extends ConsumerStatefulWidget {
  const MoviesPage({super.key});
  @override
  ConsumerState<MoviesPage> createState() => _MoviesPageState();
}

class _MoviesPageState extends ConsumerState<MoviesPage> {
  IptvItem? selected;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(filteredMoviesProvider);
    final itemsAsync = ref.watch(moviesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movies'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: MoviesFilterBar(),
        ),
      ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error')),
        data: (list) {
          if (list.isEmpty) return const Center(child: Text('No movie found'));

          return LayoutBuilder(
            builder: (c, bc) {
              final wide = bc.maxWidth >= 1100;
              final detailsW = _clamp(bc.maxWidth * 0.34, 320, 480);
              final grid = MovieGrid(
                items: list,
                selected: selected,
                onSelect: (it) => setState(() => selected = it),
              );

              if (!wide) return grid;

              final rawList = itemsAsync.value ?? const <IptvItem>[];
              final fallback = rawList.isNotEmpty ? rawList.first : list.first;
              final sel = selected ?? list.firstOrNull ?? fallback;

              return Row(
                children: [
                  SizedBox(width: bc.maxWidth - detailsW - 1, child: grid),
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: detailsW,
                    child: MovieDetailsPane(item: sel),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  double _clamp(double v, double min, double max) {
    if (v < min) return min;
    if (v > max) return max;
    return v;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
