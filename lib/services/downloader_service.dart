import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../core/settings.dart';
import '../data/download_models.dart';
import '../data/download_repository.dart';
import 'prober.dart';
import 'segment_worker.dart';

class DownloaderService {
  final Dio _dio;
  final CookieJar _jar;
  final DownloadRepository _repo;
  final Map<int, List<CancelToken>> _tokens = {};
  final Map<int, int> _lastBytes = {};
  final Map<int, DateTime> _lastTime = {};

  DownloaderService(this._dio, this._jar, this._repo);

  static DownloaderService create(DownloadRepository repo) {
    final jar = CookieJar();
    final dio = Dio(
      BaseOptions(
        connectTimeout: Duration(milliseconds: settings.connectTimeoutMs),
        receiveTimeout: Duration(milliseconds: settings.receiveTimeoutMs),
        headers: {'user-agent': settings.defaultUserAgent},
        followRedirects: true,
        maxRedirects: 10,
        validateStatus: (s) => s != null && s < 500,
      ),
    );
    dio.interceptors.add(CookieManager(jar));
    return DownloaderService(dio, jar, repo);
  }

  Future<int> addTask(
    String url,
    String dir, {
    String? referer,
    String? userAgent,
  }) async {
    final prober = Prober(_dio);
    final p = await prober.probe(
      url,
      referer: referer ?? settings.defaultReferer,
      userAgent: userAgent ?? settings.defaultUserAgent,
    );
    final name = prober.resolveFileName(p.contentDisposition, p.finalUrl);
    final t = DownloadTask()
      ..url = p.finalUrl.toString()
      ..referer = referer ?? settings.defaultReferer
      ..userAgent = userAgent ?? settings.defaultUserAgent
      ..fileName = name
      ..savePath = '$dir/$name'
      ..tempPath = '$dir/$name.part'
      ..total = p.total ?? 0
      ..acceptRanges = p.acceptRanges
      ..state = 'queued';
    return await _repo.upsertTask(t);
  }

  Future<void> start(int taskId, {int? segments, int? partSize}) async {
    final t = await _repo.getTask(taskId);
    if (t == null) return;
    if (t.state == 'completed') return;
    final segs = segments ?? settings.segmentsPerFile;
    final psize = partSize ?? settings.partSizeBytes;
    await _startInternal(t, segs, psize);
  }

  Future<void> pause(int taskId) async {
    final list = _tokens[taskId] ?? [];
    for (final c in list) {
      if (!c.isCancelled) c.cancel('pause');
    }
    _tokens.remove(taskId);
    final t = await _repo.getTask(taskId);
    if (t == null) return;
    t.state = 'paused';
    await _repo.upsertTask(t);
  }

  Future<void> cancel(int taskId) async {
    await pause(taskId);
    final t = await _repo.getTask(taskId);
    if (t == null) return;
    try {
      final f = File(t.tempPath);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
    await _repo.deleteTaskCascade(taskId);
  }

  Future<void> _startInternal(
    DownloadTask task,
    int segments,
    int partSize,
  ) async {
    final url = Uri.parse(task.url);
    final total = task.total;
    if (total <= 0 || task.acceptRanges == false) {
      await _single(task);
      return;
    }
    await _preallocate(task.tempPath, total);
    final parts = await _ensureParts(task, segments, partSize);
    task.state = 'running';
    await _repo.upsertTask(task);
    _tokens[task.id] = List.generate(parts.length, (_) => CancelToken());
    _lastBytes[task.id] = task.downloaded;
    _lastTime[task.id] = DateTime.now();

    final worker = SegmentWorker(_dio);
    final futures = <Future<void>>[];
    for (int i = 0; i < parts.length; i++) {
      final p = parts[i];
      final remain = (p.end - p.start + 1) - p.downloaded;
      if (remain <= 0) continue;
      final start = p.start + p.downloaded;
      final end = p.end;
      final spec = SegmentSpec(
        url,
        task.tempPath,
        start,
        end,
        task.referer,
        task.userAgent,
        _tokens[task.id]![i],
      );
      futures.add(
        worker
            .run(spec, (n) async {
              p.downloaded += n;
              task.downloaded += n;
              _updateSpeed(task);
              await _repo.upsertPart(p);
              await _repo.upsertTask(task);
            })
            .then((_) async {
              p.state = 'done';
              await _repo.upsertPart(p);
            }),
      );
    }
    try {
      await Future.wait(futures);
      await File(task.tempPath).rename(task.savePath);
      task.state = 'completed';
      task.speedBps = 0;
      task.etaSeconds = 0;
      await _repo.upsertTask(task);
      _tokens.remove(task.id);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      task.state = 'error';
      await _repo.upsertTask(task);
    } catch (_) {
      task.state = 'error';
      await _repo.upsertTask(task);
    }
  }

  Future<void> _single(DownloadTask task) async {
    final options = Options(
      responseType: ResponseType.stream,
      followRedirects: true,
      maxRedirects: 10,
      headers: {
        if (task.referer != null) 'referer': task.referer!,
        if (task.userAgent != null) 'user-agent': task.userAgent!,
      },
    );
    final token = CancelToken();
    _tokens[task.id] = [token];
    task.state = 'running';
    await _repo.upsertTask(task);
    final resp = await _dio.get(task.url, options: options, cancelToken: token);
    final stream = resp.data.stream;
    final raf = await File(task.tempPath).open(mode: FileMode.write);
    final t0 = DateTime.now();
    int done = 0;
    await for (final chunk in stream) {
      await raf.writeFrom(chunk);
      done += chunk.length!;
      task.downloaded = done;
      _updateSpeed(task, baseTime: t0, baseBytes: 0);
      await _repo.upsertTask(task);
    }
    await raf.close();
    await File(task.tempPath).rename(task.savePath);
    task.state = 'completed';
    task.speedBps = 0;
    task.etaSeconds = 0;
    await _repo.upsertTask(task);
    _tokens.remove(task.id);
  }

  Future<List<DownloadPart>> _ensureParts(
    DownloadTask t,
    int segments,
    int partSize,
  ) async {
    final exist = await _repo.partsForTask(t.id);
    if (exist.isNotEmpty)
      return exist..sort((a, b) => a.index.compareTo(b.index));
    final count = max(1, min(segments, (t.total / partSize).ceil()));
    final parts = <DownloadPart>[];
    int start = 0;
    for (int i = 0; i < count; i++) {
      int end = i == count - 1 ? t.total - 1 : start + partSize - 1;
      final p = DownloadPart()
        ..taskId = t.id
        ..index = i
        ..start = start
        ..end = end
        ..downloaded = 0
        ..state = 'idle';
      parts.add(p);
      start = end + 1;
    }
    await _repo.putParts(parts);
    return parts;
  }

  Future<void> _preallocate(String path, int len) async {
    final f = await File(path).create(recursive: true);
    final raf = await f.open(mode: FileMode.write);
    if (len > 0) {
      await raf.setPosition(len - 1);
      await raf.writeFrom(const [0]);
    }
    await raf.close();
  }

  void _updateSpeed(DownloadTask t, {DateTime? baseTime, int? baseBytes}) {
    final now = DateTime.now();
    final lastT = baseTime ?? _lastTime[t.id] ?? now;
    final lastB = baseBytes ?? _lastBytes[t.id] ?? 0;
    final dt = now.difference(lastT).inMilliseconds / 1000.0;
    if (dt <= 0) return;
    final diff = t.downloaded - lastB;
    final inst = diff / dt;
    t.speedBps =
        t.speedBps * (1 - settings.speedSmoothing) +
        inst * settings.speedSmoothing;
    if (t.total > 0 && t.downloaded < t.total && t.speedBps > 0) {
      final rem = t.total - t.downloaded;
      t.etaSeconds = max(0, (rem / t.speedBps).round());
    } else {
      t.etaSeconds = 0;
    }
    _lastTime[t.id] = now;
    _lastBytes[t.id] = t.downloaded;
  }
}
