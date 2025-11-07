// lib/services/downloader_service.dart
import 'dart:io';
import 'dart:math';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

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
    try {
      final d = Directory(dir);
      if (!await d.exists()) {
        await d.create(recursive: true);
      }
    } catch (_) {}
    final name = _fileNameFromUrl(url);
    final t = DownloadTask()
      ..url = url
      ..referer = referer ?? settings.defaultReferer
      ..userAgent = userAgent ?? settings.defaultUserAgent
      ..fileName = name
      ..savePath = '$dir/$name'
      ..tempPath = '$dir/$name.part'
      ..total = 0
      ..acceptRanges = false
      ..state = 'queued';
    final id = await _repo.upsertTask(t);
    await _repo.addLog(id, 'info', 'queued $url');
    return id;
  }

  Future<void> start(int taskId, {int? segments, int? partSize}) async {
    final t = await _repo.getTask(taskId);
    if (t == null) return;
    if (t.state == 'completed') return;

    await _repo.addLog(t.id, 'info', 'probe start');
    final prober = Prober(_dio);

    try {
      final p = await prober.probe(
        t.url,
        referer: t.referer,
        userAgent: t.userAgent,
      );
      final nameFromHeaders = prober.resolveFileName(
        p.contentDisposition,
        p.finalUrl,
      );
      final newName = nameFromHeaders.isNotEmpty ? nameFromHeaders : t.fileName;
      final dir = File(t.savePath).parent.path;

      t.url = p.finalUrl.toString();
      t.fileName = newName;
      t.savePath = '$dir/$newName';
      t.tempPath = '$dir/$newName.part';
      t.total = p.total ?? 0;
      t.acceptRanges = p.acceptRanges;

      await _repo.upsertTask(t);
      await _repo.addLog(
        t.id,
        'info',
        'probe ok total=${t.total} acceptRanges=${t.acceptRanges}',
      );
    } catch (e) {
      t.state = 'error';
      await _repo.upsertTask(t);
      await _repo.addLog(t.id, 'error', 'probe fail $e');
      return;
    }

    final segs = segments ?? settings.segmentsPerFile;
    final psize = partSize ?? settings.partSizeBytes;
    await _startInternal(t, segs, psize);
  }

  Future<void> retry(int taskId) async {
    await pause(taskId);
    final t = await _repo.getTask(taskId);
    if (t == null) return;

    try {
      final f = File(t.tempPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}

    await _repo.clearParts(taskId);
    t.downloaded = 0;
    t.speedBps = 0;
    t.etaSeconds = 0;
    t.state = 'queued';
    await _repo.upsertTask(t);
    await _repo.addLog(taskId, 'info', 'retry');
    await start(taskId);
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
    await _repo.addLog(taskId, 'info', 'paused');
  }

  Future<void> cancel(int taskId) async {
    await pause(taskId);
    final t = await _repo.getTask(taskId);
    if (t == null) return;

    try {
      final f = File(t.tempPath);
      if (await f.exists()) await f.delete();
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

    try {
      await _preallocate(task.tempPath, total);
    } on FileSystemException catch (e) {
      if (_isOpNotPermitted(e)) {
        await _applyFallbackPaths(task);
        await _preallocate(task.tempPath, total);
      } else {
        rethrow;
      }
    }

    final parts = await _ensureParts(task, segments, partSize);
    task.state = 'running';
    await _repo.upsertTask(task);
    await _repo.addLog(
      task.id,
      'info',
      'start segmented count=${parts.length}',
    );

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
      await _repo.addLog(task.id, 'info', 'completed');
      _tokens.remove(task.id);
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      task.state = 'error';
      await _repo.upsertTask(task);
      await _repo.addLog(task.id, 'error', 'dio $e');
    } catch (e) {
      task.state = 'error';
      await _repo.upsertTask(task);
      await _repo.addLog(task.id, 'error', 'error $e');
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
    await _repo.addLog(task.id, 'info', 'start single');

    final resp = await _dio.get(task.url, options: options, cancelToken: token);
    final Stream<List<int>> stream = resp.data.stream;

    RandomAccessFile raf;
    try {
      raf = await File(task.tempPath).open(mode: FileMode.write);
    } on FileSystemException catch (e) {
      if (_isOpNotPermitted(e)) {
        await _applyFallbackPaths(task);
        raf = await File(task.tempPath).open(mode: FileMode.write);
      } else {
        rethrow;
      }
    }

    final t0 = DateTime.now();
    int done = 0;

    await for (final List<int> chunk in stream) {
      await raf.writeFrom(chunk);
      done += chunk.length;
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
    await _repo.addLog(task.id, 'info', 'completed');
    _tokens.remove(task.id);
  }

  Future<List<DownloadPart>> _ensureParts(
    DownloadTask t,
    int segments,
    int partSize,
  ) async {
    final exist = await _repo.partsForTask(t.id);
    if (exist.isNotEmpty) {
      exist.sort((a, b) => a.index.compareTo(b.index));
      return exist;
    }

    final count = max(1, min(segments, (t.total / partSize).ceil()));
    final parts = <DownloadPart>[];
    int start = 0;

    for (int i = 0; i < count; i++) {
      final end = i == count - 1 ? t.total - 1 : start + partSize - 1;
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
    try {
      final f = await File(path).create(recursive: true);
      final raf = await f.open(mode: FileMode.write);
      if (len > 0) {
        await raf.setPosition(len - 1);
        await raf.writeFrom(const [0]);
      }
      await raf.close();
    } on FileSystemException catch (e) {
      if (_isOpNotPermitted(e)) {
        rethrow;
      }
      rethrow;
    }
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

  bool _isOpNotPermitted(Object e) {
    if (e is FileSystemException) {
      final code = e.osError?.errorCode;
      final msg = (e.osError?.message ?? e.message).toLowerCase();
      if (code == 1) return true; // EPERM
      if (msg.contains('operation not permitted') || msg.contains('eperm')) {
        return true;
      }
    }
    return false;
  }

  Future<String> _fallbackPath(String fileName) async {
    final dir = await getApplicationSupportDirectory();
    final dl = Directory('${dir.path}/Downloads');
    if (!await dl.exists()) {
      await dl.create(recursive: true);
    }
    return '${dl.path}/$fileName';
  }

  Future<void> _applyFallbackPaths(DownloadTask t) async {
    final newSave = await _fallbackPath(t.fileName);
    t.savePath = newSave;
    t.tempPath = '$newSave.part';
    await _repo.upsertTask(t);
    await _repo.addLog(
      t.id,
      'warn',
      'fallback to ${File(newSave).parent.path}',
    );
  }

  String _fileNameFromUrl(String url) {
    final u = Uri.parse(url);
    if (u.pathSegments.isNotEmpty) {
      final last = u.pathSegments.last;
      if (last.isNotEmpty) return last;
    }
    return 'download.bin';
  }
}
