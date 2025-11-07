import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/download_repository.dart';
import '../data/download_models.dart';
import '../services/downloader_service.dart';

final repositoryProvider = Provider<DownloadRepository>(
  (ref) => DownloadRepository(),
);
final downloaderProvider = Provider<DownloaderService>(
  (ref) => DownloaderService.create(ref.read(repositoryProvider)),
);

final downloadListProvider = StreamProvider<List<DownloadTask>>((ref) {
  return ref.read(repositoryProvider).watchAll();
});

class DownloadListVm extends StateNotifier<AsyncValue<void>> {
  final DownloaderService service;
  DownloadListVm(this.service) : super(const AsyncValue.data(null));

  Future<void> addOnly(
    String url,
    String dir, {
    String? referer,
    String? userAgent,
  }) async {
    state = const AsyncValue.loading();
    try {
      await service.addTask(url, dir, referer: referer, userAgent: userAgent);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> start(int id) => service.start(id);
  Future<void> pause(int id) => service.pause(id);
  Future<void> delete(int id) => service.cancel(id);
  Future<void> retry(int id) => service.retry(id);
}

final listVmProvider = StateNotifierProvider<DownloadListVm, AsyncValue<void>>(
  (ref) => DownloadListVm(ref.read(downloaderProvider)),
);
