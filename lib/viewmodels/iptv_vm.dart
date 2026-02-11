import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/iptv_repository.dart';
import '../data/iptv_models.dart';

final iptvRepoProvider = Provider<IptvRepository>(
  (ref) => IptvRepository(Dio()),
);


// State for paginated lists
class PaginatedIptvState {
  final List<IptvItem> items;
  final bool isLoading;
  final bool hasMore;
  final int offset;
  final String query;
  final String? group;
  final String? host;
  final String sortKey;
  final bool sortAsc;

  const PaginatedIptvState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.offset = 0,
    this.query = '',
    this.group,
    this.host,
    this.sortKey = 'Name',
    this.sortAsc = true,
  });

  PaginatedIptvState copyWith({
    List<IptvItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? offset,
    String? query,
    String? group,
    String? host,
    String? sortKey,
    bool? sortAsc,
  }) {
    return PaginatedIptvState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      query: query ?? this.query,
      group: group ?? this.group,
      host: host ?? this.host,
      sortKey: sortKey ?? this.sortKey,
      sortAsc: sortAsc ?? this.sortAsc,
    );
  }
}

class PaginatedIptvNotifier extends StateNotifier<PaginatedIptvState> {
  final IptvRepository _repo;
  final String _kind;
  static const int _limit = 50;

  PaginatedIptvNotifier(this._repo, this._kind)
      : super(const PaginatedIptvState()) {
    loadNext();
  }

  Future<void> loadNext() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final newItems = await _repo.findItems(
        kind: _kind,
        offset: state.offset,
        limit: _limit,
        query: state.query,
        group: state.group,
        host: state.host,
        sortKey: state.sortKey,
        sortAsc: state.sortAsc,
      );

      state = state.copyWith(
        items: [...state.items, ...newItems],
        offset: state.offset + newItems.length,
        hasMore: newItems.length >= _limit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> setQuery(String q) async {
    if (state.query == q) return;
    state = state.copyWith(query: q, offset: 0, hasMore: true, isLoading: true);
    await _reload();
  }

  Future<void> setGroup(String? g) async {
    if (state.group == g) return;
    // Manual copy because copyWith ignores nulls for nullable fields
    state = PaginatedIptvState(
      items: state.items,
      isLoading: true,
      hasMore: true,
      offset: 0,
      query: state.query,
      group: g,
      host: state.host,
      sortKey: state.sortKey,
      sortAsc: state.sortAsc,
    );
    await _reload();
  }

  Future<void> setHost(String? h) async {
    if (state.host == h) return;
    // Manual copy because copyWith ignores nulls for nullable fields
    state = PaginatedIptvState(
      items: state.items,
      isLoading: true,
      hasMore: true,
      offset: 0,
      query: state.query,
      group: state.group,
      host: h,
      sortKey: state.sortKey,
      sortAsc: state.sortAsc,
    );
    await _reload();
  }

  Future<void> setSort(String key, bool asc) async {
    if (state.sortKey == key && state.sortAsc == asc) return;
    state = state.copyWith(sortKey: key, sortAsc: asc, offset: 0, hasMore: true, isLoading: true);
    await _reload();
  }

  // _resetState is no longer needed in its previous form or can be simplified
  // ensuring we don't clear items aggressively.

  Future<void> refresh() async {
    state = state.copyWith(offset: 0, hasMore: true, isLoading: true);
    await _reload();
  }
  
  // Helper methods for UI aggregations
  Future<List<String>> getAvailableGroups() => _repo.getGroups(_kind);
  Future<List<String>> getAvailableHosts() => _repo.getHosts(_kind);

  Future<void> _reload() async {
    try {
      final newItems = await _repo.findItems(
        kind: _kind,
        offset: 0,
        limit: _limit,
        query: state.query,
        group: state.group,
        host: state.host,
        sortKey: state.sortKey,
        sortAsc: state.sortAsc,
      );

      state = state.copyWith(
        items: newItems,
        offset: newItems.length,
        hasMore: newItems.length >= _limit,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final liveVmProvider = StateNotifierProvider<PaginatedIptvNotifier, PaginatedIptvState>(
  (ref) => PaginatedIptvNotifier(ref.read(iptvRepoProvider), 'live'),
);

final moviesVmProvider = StateNotifierProvider<PaginatedIptvNotifier, PaginatedIptvState>(
  (ref) => PaginatedIptvNotifier(ref.read(iptvRepoProvider), 'movie'),
);

final seriesVmProvider = StateNotifierProvider<PaginatedIptvNotifier, PaginatedIptvState>(
  (ref) => PaginatedIptvNotifier(ref.read(iptvRepoProvider), 'series'),
);

final sourcesProvider = FutureProvider<List<IptvSource>>(
  (ref) => ref.read(iptvRepoProvider).listSources(),
);

class IptvVm extends StateNotifier<AsyncValue<void>> {
  final IptvRepository repo;
  final Ref ref;
  
  IptvVm(this.repo, this.ref) : super(const AsyncData(null));

  Future<int> addM3u(String name, String url) async {
    state = const AsyncLoading();
    try {
      final id = await repo.addM3uSource(name, url);
      await repo.refreshSource(id);
      _invalidateLists();
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<int> addXtream(
    String name,
    String server,
    String user,
    String pass,
  ) async {
    state = const AsyncLoading();
    try {
      final id = await repo.addXtream(name, server, user, pass);
      await repo.refreshSource(id);
      _invalidateLists();
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> refresh(int sourceId) async {
    await repo.refreshSource(sourceId);
    _invalidateLists();
  }
  
  Future<void> remove(int sourceId) async {
    await repo.deleteSource(sourceId);
    _invalidateLists();
  }
  
  void _invalidateLists() {
    ref.invalidate(liveVmProvider);
    ref.invalidate(moviesVmProvider);
    ref.invalidate(seriesVmProvider);
  }
}

final iptvVmProvider = StateNotifierProvider<IptvVm, AsyncValue<void>>(
  (ref) => IptvVm(ref.read(iptvRepoProvider), ref),
);
