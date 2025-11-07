import 'dart:io';
import 'package:dio/dio.dart';

class SegmentSpec {
  final Uri url;
  final String path;
  final int start;
  final int end;
  final String? referer;
  final String? userAgent;
  final CancelToken cancelToken;
  SegmentSpec(
    this.url,
    this.path,
    this.start,
    this.end,
    this.referer,
    this.userAgent,
    this.cancelToken,
  );
}

class SegmentWorker {
  final Dio dio;
  SegmentWorker(this.dio);

  Future<int> run(SegmentSpec s, void Function(int) onChunk) async {
    final options = Options(
      responseType: ResponseType.stream,
      followRedirects: true,
      maxRedirects: 10,
      headers: {
        'range': 'bytes=${s.start}-${s.end}',
        if (s.referer != null) 'referer': s.referer!,
        if (s.userAgent != null) 'user-agent': s.userAgent!,
      },
    );
    final resp = await dio.getUri(
      s.url,
      options: options,
      cancelToken: s.cancelToken,
    );
    if (resp.statusCode != 206 && resp.statusCode != 200) {
      throw HttpException('seg ${resp.statusCode}');
    }
    final stream = resp.data.stream;
    final raf = await File(s.path).open(mode: FileMode.write);
    await raf.setPosition(s.start);
    int c = 0;
    await for (final chunk in stream) {
      await raf.writeFrom(chunk);
      c += chunk.length;
      onChunk(chunk.length);
    }
    await raf.close();
    return c;
  }
}
