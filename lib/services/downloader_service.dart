// lib/services/downloader_service.dart
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../core/settings.dart';
import '../data/download_models.dart';
import '../data/download_repository.dart';
import 'prober.dart';
import 'segment_worker.dart';

class _PageMeta {
  final String? title;
  final DateTime? datePublished;
  const _PageMeta({this.title, this.datePublished});
}

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
        headers: {
          'user-agent': settings.defaultUserAgent,
          'accept-encoding': 'identity',
        },
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
    String? fileName,
  }) async {
    try {
      final d = Directory(dir);
      if (!await d.exists()) {
        await d.create(recursive: true);
      }
    } catch (_) {}

    final base = (fileName?.trim().isNotEmpty ?? false)
        ? _sanitizeFileName(fileName!.trim())
        : _sanitizeFileName(_fileNameFromUrl(url));

    final t = DownloadTask()
      ..url = url
      ..referer = referer ?? settings.defaultReferer
      ..userAgent = userAgent ?? settings.defaultUserAgent
      ..fileName = base
      ..savePath = '$dir/$base'
      ..tempPath = '$dir/$base.part'
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

    Future<bool> probeOnce() async {
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
        var candidate = _isPlausibleFileName(nameFromHeaders)
            ? nameFromHeaders
            : t.fileName;
        candidate = _sanitizeFileName(candidate);
        candidate = _ensureExtension(candidate, p.finalUrl);

        final base0 = _splitNameExt(candidate)[0];
        if (_isGenericBase(base0)) {
          final meta0 = await _tryResolvePageMeta(
            referer: t.referer,
            finalUrl: p.finalUrl.toString(),
            userAgent: t.userAgent,
          );
          if ((meta0.title ?? '').trim().isNotEmpty) {
            candidate = _ensureExtension(
              _sanitizeFileName(meta0.title!.trim()),
              p.finalUrl,
            );
          }
        }

        DateTime? lm;
        try {
          final head = await _dio.head(
            p.finalUrl.toString(),
            options: Options(
              followRedirects: true,
              maxRedirects: 0,
              validateStatus: (s) => s != null && s < 500,
              headers: {
                'accept-encoding': 'identity',
                if (t.referer != null) 'referer': t.referer!,
                if (t.userAgent != null) 'user-agent': t.userAgent!,
              },
            ),
          );
          final lmStr = head.headers.value('last-modified');
          if (lmStr != null) lm = HttpDate.parse(lmStr);
        } catch (_) {}

        var base1 = _splitNameExt(candidate)[0];
        if (_isGenericBase(base1)) {
          base1 = 'Video';
          candidate = _ensureExtension(base1, p.finalUrl);
        }

        final meta = await _tryResolvePageMeta(
          referer: t.referer,
          finalUrl: p.finalUrl.toString(),
          userAgent: t.userAgent,
        );
        final dt = meta.datePublished ?? lm ?? DateTime.now();
        final dated = _prefixDate(candidate, dt);

        final dir = File(t.savePath).parent.path;
        final unique = _dedupeNameInDir(dir, dated);

        final oldTemp = t.tempPath;
        final oldSave = t.savePath;

        t.url = p.finalUrl.toString();
        t.fileName = unique;
        t.savePath = '$dir/$unique';
        t.tempPath = '$dir/$unique.part';
        t.total = p.total ?? 0;
        t.acceptRanges = p.acceptRanges;

        if (oldTemp != t.tempPath) {
          try {
            final f = File(oldTemp);
            if (await f.exists()) {
              await f.rename(t.tempPath);
              await _repo.addLog(t.id, 'info', 'moved part to ${t.tempPath}');
            }
          } catch (e) {
            await _repo.addLog(t.id, 'warn', 'move part failed: $e');
          }
        }
        if (oldSave != t.savePath) {
          try {
            final f = File(oldSave);
            if (await f.exists() && oldSave != t.tempPath) {
              final b = await f.length();
              await _repo.addLog(t.id, 'warn', 'old save file ignored size=$b');
            }
          } catch (_) {}
        }

        await _repo.upsertTask(t);
        await _repo.addLog(
          t.id,
          'info',
          'probe ok total=${t.total} acceptRanges=${t.acceptRanges} name=${t.fileName}',
        );
        return true;
      } catch (e) {
        if (e is DioException &&
            e.error is SocketException &&
            _isOpNotPermitted(e.error.toString())) {
          await _repo.addLog(
            t.id,
            'error',
            'EPERM: réseau bloqué par le sandbox macOS. Active Outgoing Connections (Client) et rebuild.',
          );
        } else {
          await _repo.addLog(t.id, 'error', 'probe fail $e');
        }
        return false;
      }
    }

    var ok = await probeOnce();

    if (!ok && t.url.startsWith('http://')) {
      final https = t.url.replaceFirst('http://', 'https://');
      await _repo.addLog(t.id, 'warn', 'retry probe with https: $https');
      t.url = https;
      await _repo.upsertTask(t);
      ok = await probeOnce();
    }

    if (!ok) {
      t.state = 'error';
      await _repo.upsertTask(t);
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

      if (task.total > 0 && task.downloaded != task.total) {
        task.state = 'error';
        await _repo.upsertTask(task);
        await _repo.addLog(
          task.id,
          'error',
          'size mismatch: got=${task.downloaded} expected=${task.total}',
        );
        return;
      }

      await File(task.tempPath).rename(task.savePath);
      await _maybeUnquarantine(task);
      await _setWhereFromsForTask(task);

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
    task.state = 'running';
    await _repo.upsertTask(task);
    await _repo.addLog(task.id, 'info', 'start single');

    final tmpFile = File(task.tempPath);
    int downloaded = 0;
    if (await tmpFile.exists()) {
      downloaded = await tmpFile.length();
    } else {
      await tmpFile.create(recursive: true);
    }

    if (downloaded != task.downloaded) {
      task.downloaded = downloaded;
      await _repo.upsertTask(task);
    }

    final raf = await tmpFile.open(mode: FileMode.write);
    await raf.setPosition(downloaded);

    int attempt = 0;
    const maxAttempts = 8;

    try {
      while (true) {
        final token = CancelToken();
        _tokens[task.id] = [token];

        final headers = <String, String>{
          'accept-encoding': 'identity',
          'connection': 'keep-alive',
          if (task.referer != null) 'referer': task.referer!,
          if (task.userAgent != null) 'user-agent': task.userAgent!,
        };

        if (downloaded > 0) {
          headers['range'] = 'bytes=$downloaded-';
        }

        Response<ResponseBody> resp;
        try {
          resp = await _dio.get<ResponseBody>(
            task.url,
            options: Options(
              responseType: ResponseType.stream,
              followRedirects: true,
              maxRedirects: 10,
              headers: headers,
              validateStatus: (s) => s != null && s < 500,
            ),
            cancelToken: token,
          );
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) {
            await _repo.addLog(task.id, 'info', 'cancelled');
            return;
          }
          attempt++;
          final delay = Duration(seconds: min(8, 1 << attempt));
          await _repo.addLog(
            task.id,
            'warn',
            'request fail $e → retry in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
          if (attempt >= maxAttempts) {
            task.state = 'error';
            await _repo.upsertTask(task);
            await _repo.addLog(task.id, 'error', 'max retries reached');
            return;
          }
          continue;
        }

        final status = resp.statusCode ?? 0;
        await _repo.addLog(
          task.id,
          'info',
          'GET ${resp.realUri} status=$status',
        );

        final contentRange = resp.headers.value('content-range');
        if (contentRange != null) {
          final m = RegExp(r'/(\d+)$').firstMatch(contentRange);
          final tot = m != null ? int.tryParse(m.group(1)!) : null;
          if (tot != null && task.total == 0) {
            task.total = tot;
            await _repo.upsertTask(task);
          }
        } else if (status == 200) {
          final cl = int.tryParse(resp.headers.value('content-length') ?? '');
          if (downloaded == 0 && cl != null && task.total == 0) {
            task.total = cl;
            await _repo.upsertTask(task);
          }
          if (downloaded > 0) {
            await _repo.addLog(
              task.id,
              'warn',
              'server ignored Range, restarting from 0',
            );
            downloaded = 0;
            task.downloaded = 0;
            await raf.truncate(0);
            await raf.setPosition(0);
            await _repo.upsertTask(task);
          }
        }

        int readThisAttempt = 0;
        final stream = resp.data!.stream;
        final t0 = DateTime.now();
        final baseBytes = downloaded;

        try {
          await for (final chunk in stream) {
            await raf.writeFrom(chunk);
            downloaded += chunk.length;
            readThisAttempt += chunk.length;

            task.downloaded = downloaded;
            _updateSpeed(task, baseTime: t0, baseBytes: baseBytes);
            await _repo.upsertTask(task);
          }
        } on Object catch (e) {
          if (e is DioException && CancelToken.isCancel(e)) {
            await _repo.addLog(task.id, 'info', 'cancelled');
            return;
          }
          attempt++;
          final delay = Duration(seconds: min(8, 1 << attempt));
          await _repo.addLog(
            task.id,
            'warn',
            'stream error $e after $readThisAttempt bytes → retry in ${delay.inSeconds}s',
          );
          await Future.delayed(delay);
          if (attempt >= maxAttempts) {
            task.state = 'error';
            await _repo.upsertTask(task);
            await _repo.addLog(task.id, 'error', 'max retries reached');
            return;
          }
          continue;
        }

        attempt = 0;

        if (task.total > 0 && downloaded >= task.total) {
          break;
        }

        if (readThisAttempt == 0) {
          await _repo.addLog(
            task.id,
            'error',
            'connection closed with no progress',
          );
          task.state = 'error';
          await _repo.upsertTask(task);
          return;
        }
      }
    } finally {
      await raf.close();
    }

    await File(task.tempPath).rename(task.savePath);
    await _maybeUnquarantine(task);
    await _setWhereFromsForTask(task);

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
      if (code == 1) return true;
      if (msg.contains('operation not permitted') || msg.contains('eperm')) {
        return true;
      }
    }
    if (e is SocketException) {
      final m = (e.message).toLowerCase();
      if (m.contains('operation not permitted') || m.contains('eperm')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _maybeUnquarantine(DownloadTask t) async {
    if (!Platform.isMacOS) return;
    try {
      final probe = await Process.run('/usr/bin/xattr', [
        '-p',
        'com.apple.quarantine',
        t.savePath,
      ]);
      if (probe.exitCode == 0) {
        await Process.run('/usr/bin/xattr', [
          '-d',
          'com.apple.quarantine',
          t.savePath,
        ]);
        await _repo.addLog(t.id, 'info', 'removed quarantine on ${t.fileName}');
      }
    } catch (e) {
      await _repo.addLog(t.id, 'warn', 'unquarantine failed: $e');
    }
  }

  Future<void> _setWhereFromsForTask(DownloadTask t) async {
    if (!Platform.isMacOS) return;
    final urls = <String>[
      t.url,
      if (t.referer != null) t.referer!,
    ].where((s) => s.isNotEmpty).toList();
    if (urls.isEmpty) return;

    try {
      final tmp = await getTemporaryDirectory();
      final xmlFile = File(
        '${tmp.path}/wherefroms_${DateTime.now().microsecondsSinceEpoch}.plist',
      );
      final binFile = File('${xmlFile.path}.bin');

      final xml = _plistForUrls(urls);
      await xmlFile.writeAsString(xml, flush: true);

      final conv = await Process.run('/usr/bin/plutil', [
        '-convert',
        'binary1',
        '-o',
        binFile.path,
        xmlFile.path,
      ]);
      if (conv.exitCode != 0) {
        await _repo.addLog(t.id, 'warn', 'plutil failed: ${conv.stderr}');
        await _safeDelete(xmlFile);
        await _safeDelete(binFile);
        return;
      }

      final bytes = await binFile.readAsBytes();
      final hex = _hexFromBytes(bytes);

      final xr = await Process.run('/usr/bin/xattr', [
        '-w',
        '-x',
        'com.apple.metadata:kMDItemWhereFroms',
        hex,
        t.savePath,
      ]);
      if (xr.exitCode == 0) {
        await _repo.addLog(t.id, 'info', 'set wherefroms: ${urls.join(' | ')}');
        await Process.run('/usr/bin/mdimport', ['-f', t.savePath]);
      } else {
        await _repo.addLog(
          t.id,
          'warn',
          'xattr wherefroms failed: ${xr.stderr}',
        );
      }

      await _safeDelete(xmlFile);
      await _safeDelete(binFile);
    } catch (e) {
      await _repo.addLog(t.id, 'warn', 'wherefroms error: $e');
    }
  }

  Future<void> _safeDelete(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  String _plistForUrls(List<String> urls) {
    final esc = urls.map(_xmlEscape).toList();
    final items = esc.map((u) => '<string>$u</string>').join();
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <array>
    $items
  </array>
</plist>
''';
  }

  String _xmlEscape(String s) {
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _hexFromBytes(Uint8List b) {
    final sb = StringBuffer();
    const hex = '0123456789abcdef';
    for (final v in b) {
      sb.write(hex[(v >> 4) & 0xF]);
      sb.write(hex[v & 0xF]);
    }
    return sb.toString();
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

  String _sanitizeFileName(String raw) {
    final s = raw
        .replaceAll(RegExp(r'[\/\\:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s.isEmpty ? 'video' : s;
  }

  bool _isPlausibleFileName(String s) {
    if (s.isEmpty) return false;
    if (!s.contains('.')) return false;
    final base = _splitNameExt(s)[0];
    if (_isGenericBase(base)) return false;
    if (RegExp(r'^[A-Za-z0-9_-]{16,}$').hasMatch(s)) return false;
    if (RegExp(r'^[a-f0-9]{16,}$', caseSensitive: false).hasMatch(s)) {
      return false;
    }
    return true;
  }

  String _ensureExtension(String name, Uri finalUrl) {
    if (name.contains('.')) return name;
    final m = RegExp(r'\.([a-zA-Z0-9]{2,5})(?:$|\?)').firstMatch(finalUrl.path);
    final ext = m != null ? m.group(1) : 'mp4';
    return '$name.$ext';
  }

  String _dedupeNameInDir(String dir, String name) {
    var candidate = name;
    var i = 1;
    while (File('$dir/$candidate').existsSync() ||
        File('$dir/$candidate.part').existsSync()) {
      final parts = _splitNameExt(candidate);
      candidate = '${parts[0]} ($i)${parts[1]}';
      i++;
    }
    return candidate;
  }

  List<String> _splitNameExt(String name) {
    final idx = name.lastIndexOf('.');
    if (idx <= 0) return [name, ''];
    return [name.substring(0, idx), name.substring(idx)];
  }

  Future<void> verify(int taskId) async {
    final t = await _repo.getTask(taskId);
    if (t == null) return;
    final f = File(t.savePath);
    if (!await f.exists()) {
      await _repo.addLog(taskId, 'error', 'file not found ${t.savePath}');
      return;
    }
    final len = await f.length();
    await _repo.addLog(taskId, 'info', 'verify size=$len expected=${t.total}');
  }

  Future<void> openFile(int taskId) async {
    final t = await _repo.getTask(taskId);
    if (t == null) return;
    await _openPath(t.savePath);
  }

  Future<void> revealFile(int taskId) async {
    final t = await _repo.getTask(taskId);
    if (t == null) return;
    await _revealPath(t.savePath);
  }

  Future<void> openWithApp(int taskId, String appName) async {
    final t = await _repo.getTask(taskId);
    if (t == null) return;
    if (Platform.isMacOS) {
      await Process.run('/usr/bin/open', ['-a', appName, t.savePath]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', t.savePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [t.savePath]);
    }
  }

  Future<void> _openPath(String p) async {
    if (Platform.isMacOS) {
      await Process.run('/usr/bin/open', [p]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', p]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [p]);
    }
  }

  Future<void> _revealPath(String p) async {
    if (Platform.isMacOS) {
      await Process.run('/usr/bin/open', ['-R', p]);
    } else {
      final dir = File(p).parent.path;
      await _openPath(dir);
    }
  }

  Future<void> fullRetry(int id) async {
    return retry(id);
  }

  bool _isGenericBase(String base) {
    final b = base.trim().toLowerCase();
    if (b.isEmpty) return true;
    if (b.length <= 2) return true;
    const bad = {'id', 'file', 'video', 'download', 'index'};
    if (bad.contains(b)) return true;
    if (RegExp(r'^\d+$').hasMatch(b)) return true;
    if (RegExp(r'^[a-f0-9]{8,}$', caseSensitive: false).hasMatch(b)) {
      return true;
    }
    return false;
  }

  Future<_PageMeta> _tryResolvePageMeta({
    String? referer,
    required String finalUrl,
    String? userAgent,
  }) async {
    if ((referer ?? '').isNotEmpty) {
      final m = await _fetchMetaFrom(referer!, userAgent: userAgent);
      if (m.title != null || m.datePublished != null) return m;
    }
    try {
      final head = await _dio.head(
        finalUrl,
        options: Options(
          followRedirects: true,
          headers: {
            'accept': 'text/html,*/*;q=0.8',
            if (userAgent != null) 'user-agent': userAgent,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final ct = head.headers.value('content-type') ?? '';
      if (ct.toLowerCase().contains('text/html')) {
        return await _fetchMetaFrom(finalUrl, userAgent: userAgent);
      }
    } catch (_) {}
    return const _PageMeta();
  }

  Future<_PageMeta> _fetchMetaFrom(String url, {String? userAgent}) async {
    try {
      final resp = await _dio.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          headers: {
            'accept': 'text/html,*/*;q=0.8',
            if (userAgent != null) 'user-agent': userAgent,
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      final html = resp.data ?? '';
      final title = _extractTitle(html);
      final date = _extractDate(html);
      return _PageMeta(title: title, datePublished: date);
    } catch (_) {
      return const _PageMeta();
    }
  }

  String? _extractTitle(String html) {
    String? g(RegExp r) => r.firstMatch(html)?.group(1);
    final reOg = RegExp(
      r'''<meta[^>]+property=["\']og:title["\'][^>]*content=["\']([^"\']+)["\']''',
      caseSensitive: false,
    );
    final reTw = RegExp(
      r'''<meta[^>]+name=["\']twitter:title["\'][^>]*content=["\']([^"\']+)["\']''',
      caseSensitive: false,
    );
    final reTi = RegExp(
      r'''<title[^>]*>([^<]{1,200})</title>''',
      caseSensitive: false,
    );
    return g(reOg) ?? g(reTw) ?? g(reTi);
  }

  DateTime? _extractDate(String html) {
    String? g(RegExp r) => r.firstMatch(html)?.group(1);
    final cands = <String?>[
      g(
        RegExp(
          r'''<meta[^>]+property=["\']article:published_time["\'][^>]*content=["\']([^"\']+)["\']''',
          caseSensitive: false,
        ),
      ),
      g(
        RegExp(
          r'''<meta[^>]+property=["\']og:updated_time["\'][^>]*content=["\']([^"\']+)["\']''',
          caseSensitive: false,
        ),
      ),
      g(
        RegExp(
          r'''<meta[^>]+name=["\']date["\'][^>]*content=["\']([^"\']+)["\']''',
          caseSensitive: false,
        ),
      ),
      g(
        RegExp(
          r'''<time[^>]+datetime=["\']([^"\']+)["\']''',
          caseSensitive: false,
        ),
      ),
    ];
    for (final s in cands) {
      if (s == null) continue;
      final dt = DateTime.tryParse(s);
      if (dt != null) return dt.toLocal();
    }
    return null;
  }

  String _dateYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _prefixDate(String name, DateTime d) {
    final parts = _splitNameExt(name);
    final base = parts[0];
    final ext = parts[1];
    final prefix = _dateYmd(d);
    if (base.startsWith('$prefix ')) return name;
    return '$prefix $base$ext';
  }
}
