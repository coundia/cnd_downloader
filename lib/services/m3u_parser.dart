class M3uEntry {
  final String name;
  final String? logo;
  final String? group;
  final String url;
  final String kind;
  M3uEntry(this.name, this.logo, this.group, this.url, this.kind);
}

class M3uParser {
  List<M3uEntry> parse(String data) {
    final lines = data.split(RegExp(r'\r?\n'));
    final res = <M3uEntry>[];
    String? name;
    String? logo;
    String? group;
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('#EXTINF')) {
        name = _afterComma(line);
        logo = _attr(line, 'tvg-logo');
        group = _attr(line, 'group-title');
      } else if (!line.startsWith('#')) {
        final url = line;
        final kind = _detectKind(url, group, name);
        res.add(M3uEntry(name ?? url, logo, group, url, kind));
        name = null;
        logo = null;
        group = null;
      }
    }
    return res;
  }

  String? _attr(String s, String key) {
    final re = RegExp('$key="([^"]*)"');
    final m = re.firstMatch(s);
    return m == null ? null : m.group(1);
  }

  String _afterComma(String s) {
    final i = s.indexOf(',');
    return i >= 0 && i < s.length - 1 ? s.substring(i + 1).trim() : s.trim();
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
}
