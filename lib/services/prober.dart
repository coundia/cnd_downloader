import 'dart:io';
import 'package:dio/dio.dart';

class ProbeResult {
  final Uri finalUrl;
  final int? total;
  final bool acceptRanges;
  final String? contentDisposition;
  final String? contentType;
  ProbeResult(
    this.finalUrl,
    this.total,
    this.acceptRanges,
    this.contentDisposition,
    this.contentType,
  );
}

class Prober {
  final Dio dio;
  Prober(this.dio);

  Future<ProbeResult> probe(
    String url, {
    String? referer,
    String? userAgent,
  }) async {
    final options = Options(
      followRedirects: true,
      maxRedirects: 10,
      headers: {
        if (referer != null) 'referer': referer,
        if (userAgent != null) 'user-agent': userAgent,
      },
      validateStatus: (s) => s != null && s < 500,
    );
    Response r = await dio.head(url, options: options);
    if (r.statusCode == 405 || r.statusCode == 403 || r.statusCode == 401) {
      r = await dio.get(
        url,
        options: options.copyWith(
          headers: {...?options.headers, 'range': 'bytes=0-0'},
        ),
      );
    }
    if (r.statusCode == null ||
        (r.statusCode! < 200 || r.statusCode! >= 400 && r.statusCode != 206)) {
      throw HttpException('probe ${r.statusCode}');
    }
    final uri = Uri.parse(r.realUri.toString());
    final accept = (r.headers.value('accept-ranges') ?? '')
        .toLowerCase()
        .contains('bytes');
    final cr = r.headers.value('content-range');
    int? total;
    if (cr != null && cr.contains('/')) {
      final t = cr.split('/').last;
      total = int.tryParse(t);
    } else {
      total = int.tryParse(r.headers.value('content-length') ?? '');
    }
    return ProbeResult(
      uri,
      total,
      accept,
      r.headers.value('content-disposition'),
      r.headers.value('content-type'),
    );
  }

  String resolveFileName(String? contentDisposition, Uri uri) {
    if (contentDisposition != null) {
      final i = contentDisposition.indexOf('filename=');
      if (i >= 0) {
        var v = contentDisposition.substring(i + 9).trim();
        v = v.replaceAll('"', '').replaceAll("'", '');
        if (v.isNotEmpty) return v;
      }
    }
    final path = uri.pathSegments.isNotEmpty
        ? uri.pathSegments.last
        : 'file.bin';
    return path.split('?').first;
  }
}
