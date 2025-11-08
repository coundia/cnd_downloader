import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MoviesSort { nameAsc, nameDesc, groupAsc, hostAsc }

class MoviesFilterState {
  final String query;
  final String group;
  final String host;
  final bool onlyWithLogo;
  final MoviesSort sort;

  const MoviesFilterState({
    this.query = '',
    this.group = 'All',
    this.host = 'All',
    this.onlyWithLogo = false,
    this.sort = MoviesSort.nameAsc,
  });

  MoviesFilterState copyWith({
    String? query,
    String? group,
    String? host,
    bool? onlyWithLogo,
    MoviesSort? sort,
  }) {
    return MoviesFilterState(
      query: query ?? this.query,
      group: group ?? this.group,
      host: host ?? this.host,
      onlyWithLogo: onlyWithLogo ?? this.onlyWithLogo,
      sort: sort ?? this.sort,
    );
  }
}

class MoviesFilterVm extends StateNotifier<MoviesFilterState> {
  MoviesFilterVm() : super(const MoviesFilterState());

  void setQuery(String v) =>
      state = state.copyWith(query: v.trim().toLowerCase());
  void setGroup(String v) => state = state.copyWith(group: v);
  void setHost(String v) => state = state.copyWith(host: v);
  void toggleLogo(bool v) => state = state.copyWith(onlyWithLogo: v);
  void setSort(MoviesSort s) => state = state.copyWith(sort: s);
}

final moviesFilterProvider =
    StateNotifierProvider<MoviesFilterVm, MoviesFilterState>(
      (ref) => MoviesFilterVm(),
    );
