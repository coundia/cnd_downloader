import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/iptv_models.dart';
import '../../../../viewmodels/iptv_vm.dart';
import 'movies_filter_state.dart';
import 'movies_sort.dart';

String _host(String u) {
  try {
    return Uri.parse(u).host;
  } catch (_) {
    return '';
  }
}

final movieGroupsProvider = Provider<List<String>>((ref) {
  final data = ref.watch(moviesProvider);
  return data.when(
    loading: () => const ['All'],
    error: (_, __) => const ['All'],
    data: (list) {
      final s = <String>{};
      for (final e in list) {
        final g = (e.groupTitle ?? '').trim();
        if (g.isNotEmpty) s.add(g);
      }
      final r = s.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return ['All', ...r];
    },
  );
});

final movieHostsProvider = Provider<List<String>>((ref) {
  final data = ref.watch(moviesProvider);
  return data.when(
    loading: () => const ['All'],
    error: (_, __) => const ['All'],
    data: (list) {
      final s = <String>{};
      for (final e in list) {
        final h = _host(e.streamUrl);
        if (h.isNotEmpty) s.add(h);
      }
      final r = s.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return ['All', ...r];
    },
  );
});

final filteredMoviesProvider = Provider<AsyncValue<List<IptvItem>>>((ref) {
  final items = ref.watch(moviesProvider);
  final f = ref.watch(moviesFilterProvider);
  return items.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (list) {
      final q = f.query;
      final group = f.group;
      final host = f.host;
      Iterable<IptvItem> it = list;

      if (q.isNotEmpty) {
        it = it.where(
          (e) => ('${e.name} ${e.groupTitle ?? ''}').toLowerCase().contains(q),
        );
      }
      if (group != 'All') {
        it = it.where((e) => (e.groupTitle ?? '') == group);
      }
      if (host != 'All') {
        it = it.where((e) => _host(e.streamUrl) == host);
      }
      if (f.onlyWithLogo) {
        it = it.where((e) => (e.logo ?? '').trim().isNotEmpty);
      }

      final out = it.toList();
      sortMovies(out, f.sort);
      return AsyncData(out);
    },
  );
});
