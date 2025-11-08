class M3uDocument {
  final Map<String, String> header;
  final List<M3uEntryPlus> entries;
  M3uDocument(this.header, this.entries);
}

class M3uEntryPlus {
  final String name;
  final String? nameOriginal;
  final String? logo;
  final String? group;
  final String url;
  final String kind;

  final String? tvgId;
  final String? tvgName;
  final String? country;
  final String? language;
  final int? chno;

  final String? catchup;
  final String? catchupSource;
  final int? catchupDays;
  final String? epgShift;

  final String? userAgent;
  final String? referer;

  final Map<String, String> vlcOpts;
  final Map<String, String> kodiProps;

  // NEW: IMDb info from playlist if present
  final String? imdbId;
  final double? imdbRating;
  final String? imdbDescription;

  M3uEntryPlus({
    required this.name,
    required this.nameOriginal,
    required this.logo,
    required this.group,
    required this.url,
    required this.kind,
    required this.tvgId,
    required this.tvgName,
    required this.country,
    required this.language,
    required this.chno,
    required this.catchup,
    required this.catchupSource,
    required this.catchupDays,
    required this.epgShift,
    required this.userAgent,
    required this.referer,
    required this.vlcOpts,
    required this.kodiProps,
    required this.imdbId,
    required this.imdbRating,
    required this.imdbDescription,
  });
}

class M3uParser {
  static final _reAttr = RegExp(r'([\w\-]+)=(?:"([^"]*)"|([^,"\s]+))');
  static final _reImdbId = RegExp(r'(tt\d{7,9})', caseSensitive: false);
  static final _reNumber = RegExp(r'(\d+(?:\.\d+)?)');

  M3uDocument parseDocument(String data) {
    final lines = data.split(RegExp(r'\r?\n'));
    final header = <String, String>{};
    final entries = <M3uEntryPlus>[];

    String? name;
    String? nameOriginal;
    String? logo;
    String? group;
    String? tvgId;
    String? tvgName;
    String? country;
    String? language;
    int? chno;
    String? catchup;
    String? catchupSource;
    int? catchupDays;
    String? epgShift;
    String? userAgent;
    String? referer;

    // NEW accumulators
    String? imdbId;
    double? imdbRating;
    String? imdbDesc;

    final vlcOpts = <String, String>{};
    final kodiProps = <String, String>{};

    bool firstLine = true;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      if (firstLine && line.startsWith('#EXTM3U')) {
        firstLine = false;
        final attrs = _parseAttrs(line);
        final xUrlTvg = attrs['x-tvg-url'] ?? attrs['url-tvg'];
        if (xUrlTvg != null && xUrlTvg.isNotEmpty) header['url-tvg'] = xUrlTvg;
        if (attrs['catchup'] != null) header['catchup'] = attrs['catchup']!;
        if (attrs['catchup-source'] != null)
          header['catchup-source'] = attrs['catchup-source']!;
        if (attrs['provider-name'] != null)
          header['provider-name'] = attrs['provider-name']!;
        continue;
      }

      if (line.startsWith('#EXTINF')) {
        final attrs = _parseAttrs(line);
        nameOriginal = _afterComma(line);
        name = nameOriginal?.trim();
        logo = attrs['tvg-logo'] ?? attrs['logo'];
        group = attrs['group-title'];
        tvgId = attrs['tvg-id'];
        tvgName = attrs['tvg-name'];
        country = attrs['tvg-country'] ?? attrs['country'];
        language = attrs['tvg-language'] ?? attrs['language'];
        chno = _toInt(attrs['tvg-chno'] ?? attrs['channel-id']);
        catchup = attrs['catchup'] ?? catchup;
        catchupSource = attrs['catchup-source'] ?? catchupSource;
        catchupDays = _toInt(attrs['catchup-days'] ?? attrs['timeshift']);
        epgShift = attrs['epg-shift'] ?? epgShift;

        // IMDb from attributes
        imdbId = attrs['imdb-id'] ?? attrs['imdbid'] ?? attrs['imdb_id'];
        imdbRating = _parseRating(
          attrs['imdb'] ?? attrs['imdbrating'] ?? attrs['imdb-rating'],
        );
        imdbDesc =
            attrs['tvg-description'] ??
            attrs['tvg-desc'] ??
            attrs['description'] ??
            attrs['plot'];

        // Also scan the whole line text for tt123... or rating patterns
        imdbId ??= _matchImdbId(line);
        imdbRating ??= _parseRating(_matchNumberTokenAfter(line, 'imdb'));
        continue;
      }

      if (line.startsWith('#EXTGRP:')) {
        group = line.substring(8).trim();
        continue;
      }

      if (line.startsWith('#EXTVLCOPT:')) {
        final kv = line.substring(12);
        final i = kv.indexOf('=');
        if (i > 0) {
          final k = kv.substring(0, i).trim();
          final v = kv.substring(i + 1).trim();
          vlcOpts[k] = v;
          final lk = k.toLowerCase();
          if (lk.contains('http-user-agent')) userAgent = v;
          if (lk.contains('http-referrer') || lk.contains('http-referrer'))
            referer = v;
          if (lk.contains('imdb')) {
            imdbId ??= _matchImdbId(v);
            imdbRating ??= _parseRating(v);
          }
        }
        continue;
      }

      if (line.startsWith('#KODIPROP:')) {
        final kv = line.substring(11);
        final i = kv.indexOf('=');
        if (i > 0) {
          final k = kv.substring(0, i).trim();
          final v = kv.substring(i + 1).trim();
          kodiProps[k] = v;
          final lk = k.toLowerCase();
          if (lk.contains('imdb')) {
            imdbId ??= _matchImdbId(v);
            imdbRating ??= _parseRating(v);
          }
          if (lk.contains('plot') || lk.contains('description')) {
            imdbDesc ??= v;
          }
        }
        continue;
      }

      if (!line.startsWith('#')) {
        final url = line;

        // IMDb hints from URL or name
        imdbId ??= _matchImdbId(url);
        imdbId ??= _matchImdbId(name ?? '');
        imdbRating ??= _parseRating(name ?? '');

        final kind = _detectKind(url, group, name);

        entries.add(
          M3uEntryPlus(
            name: name ?? url,
            nameOriginal: nameOriginal,
            logo: logo,
            group: group,
            url: url,
            kind: kind,
            tvgId: tvgId,
            tvgName: tvgName,
            country: country,
            language: language,
            chno: chno,
            catchup: catchup,
            catchupSource: catchupSource,
            catchupDays: catchupDays,
            epgShift: epgShift,
            userAgent: userAgent,
            referer: referer,
            vlcOpts: Map.of(vlcOpts),
            kodiProps: Map.of(kodiProps),
            imdbId: imdbId,
            imdbRating: imdbRating,
            imdbDescription: imdbDesc,
          ),
        );

        // reset accumulators
        name = null;
        nameOriginal = null;
        logo = null;
        group = null;
        tvgId = null;
        tvgName = null;
        country = null;
        language = null;
        chno = null;
        catchup = null;
        catchupSource = null;
        catchupDays = null;
        epgShift = null;
        userAgent = null;
        referer = null;
        imdbId = null;
        imdbRating = null;
        imdbDesc = null;
        vlcOpts.clear();
        kodiProps.clear();
      }
    }

    return M3uDocument(header, entries);
  }

  List<M3uEntryPlus> parse(String data) => parseDocument(data).entries;

  Map<String, String> _parseAttrs(String s) {
    final out = <String, String>{};
    for (final m in _reAttr.allMatches(s)) {
      final k = m.group(1)!;
      final v = (m.group(2) ?? m.group(3) ?? '').trim();
      out[k] = v;
    }
    return out;
  }

  String _afterComma(String s) {
    final i = s.indexOf(',');
    return i >= 0 && i < s.length - 1 ? s.substring(i + 1).trim() : s.trim();
  }

  int? _toInt(String? s) {
    if (s == null) return null;
    return int.tryParse(s.trim());
  }

  String? _matchImdbId(String text) {
    final m = _reImdbId.firstMatch(text);
    return m?.group(1)?.toLowerCase();
  }

  double? _parseRating(String? text) {
    if (text == null || text.isEmpty) return null;
    // accept "7.4/10", "7,4", "IMDB 7.4", etc.
    final t = text.replaceAll(',', '.');
    final m = _reNumber.firstMatch(t);
    if (m == null) return null;
    final v = double.tryParse(m.group(1)!);
    if (v == null) return null;
    // normalize percentages like "77%" if someone put that
    if (t.contains('%')) return (v / 10.0).clamp(0.0, 10.0);
    // if clearly > 10, treat as /100 then normalize
    if (v > 10.0 && v <= 100.0) return (v / 10.0).clamp(0.0, 10.0);
    return v.clamp(0.0, 10.0);
  }

  String _detectKind(String url, String? group, String? name) {
    final lurl = url.toLowerCase();
    final lg = (group ?? '').toLowerCase();
    final ln = (name ?? '').toLowerCase();
    if (lurl.contains('/movie/') ||
        lg.contains('vod') ||
        lg.contains('movie') ||
        ln.contains('vod'))
      return 'movie';
    if (lurl.contains('/series/') ||
        lg.contains('series') ||
        ln.contains('season'))
      return 'series';
    return 'live';
  }

  /// Returns the first numeric token that appears after [token] in [text].
  /// Examples it matches after "imdb": "7.4", "7,4", "7.4/10", "77%".
  /// Case-insensitive. Returns `null` if no match.
  String? _matchNumberTokenAfter(String text, String token) {
    if (text.isEmpty || token.isEmpty) return null;
    final tLower = token.toLowerCase();
    final i = text.toLowerCase().indexOf(tLower);
    if (i < 0) return null;

    // Scan only the suffix after the token.
    final suffix = text.substring(i + token.length);

    // Optional separators (: = - whitespace), then number with optional decimal.
    // Optionally followed by "/10" or "%" which _parseRating can interpret.
    final re = RegExp(
      r'[:=\-\s]*([0-9]+(?:[.,][0-9]+)?)(?:\s*/\s*10|\s*%)?',
      caseSensitive: false,
    );

    final m = re.firstMatch(suffix);
    if (m == null) return null;

    // Return full matched token, e.g., "7.4/10" or "77%".
    return m.group(0)?.trim();
  }
}
