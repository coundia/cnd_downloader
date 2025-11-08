import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../data/iptv_repository.dart';
import '../data/iptv_models.dart';

final iptvRepoProvider = Provider<IptvRepository>(
  (ref) => IptvRepository(Dio()),
);

final liveProvider = StreamProvider<List<IptvItem>>(
  (ref) => ref.read(iptvRepoProvider).watchLive(),
);
final moviesProvider = StreamProvider<List<IptvItem>>(
  (ref) => ref.read(iptvRepoProvider).watchMovies(),
);
final seriesProvider = StreamProvider<List<IptvItem>>(
  (ref) => ref.read(iptvRepoProvider).watchSeries(),
);
final sourcesProvider = FutureProvider<List<IptvSource>>(
  (ref) => ref.read(iptvRepoProvider).listSources(),
);

class IptvVm extends StateNotifier<AsyncValue<void>> {
  final IptvRepository repo;
  IptvVm(this.repo) : super(const AsyncData(null));

  Future<int> addM3u(String name, String url) async {
    state = const AsyncLoading();
    try {
      final id = await repo.addM3uSource(name, url);
      await repo.refreshSource(id);
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
      state = const AsyncData(null);
      return id;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> refresh(int sourceId) => repo.refreshSource(sourceId);
  Future<void> remove(int sourceId) => repo.deleteSource(sourceId);
}

final iptvVmProvider = StateNotifierProvider<IptvVm, AsyncValue<void>>(
  (ref) => IptvVm(ref.read(iptvRepoProvider)),
);
