import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/iptv_models.dart';
import '../../core/settings.dart';
import '../widgets/cnd_video_player.dart';
import 'episodePlay.dart';
import 'playlist_player_page.dart';

class SeriesDetailsPage extends StatefulWidget {
  final String seriesKey;
  final List<IptvItem> episodes; // déjà triés S/E par l’appelant
  const SeriesDetailsPage({
    super.key,
    required this.seriesKey,
    required this.episodes,
  });

  @override
  State<SeriesDetailsPage> createState() => _SeriesDetailsPageState();
}

class _SeriesDetailsPageState extends State<SeriesDetailsPage>
    with SingleTickerProviderStateMixin {
  late final Map<int, List<IptvItem>> _bySeason;
  late final List<int> _seasons;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _bySeason = _groupBySeason(widget.episodes);
    _seasons = _bySeason.keys.toList()..sort();
    _tabs = TabController(length: _seasons.length, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Map<int, List<IptvItem>> _groupBySeason(List<IptvItem> eps) {
    final m = <int, List<IptvItem>>{};
    for (final e in eps) {
      final s = _parseSeason(e.name);
      (m[s] ??= <IptvItem>[]).add(e);
    }
    for (final list in m.values) {
      list.sort(
        (a, b) => _parseEpisode(a.name).compareTo(_parseEpisode(b.name)),
      );
    }
    return m;
  }

  int _parseSeason(String name) {
    final m =
        RegExp(r'[Ss]\s*(\d{1,2})').firstMatch(name) ??
        RegExp(r'Season\s*(\d{1,2})', caseSensitive: false).firstMatch(name);
    return m != null ? int.tryParse(m.group(1)!) ?? 1 : 1;
  }

  int _parseEpisode(String name) {
    final m =
        RegExp(r'[Ee]\s*(\d{1,3})').firstMatch(name) ??
        RegExp(
          r'(?:Ep|Episode)\s*(\d{1,3})',
          caseSensitive: false,
        ).firstMatch(name) ??
        RegExp(r'(\d{1,3})$').firstMatch(name.trim());
    return m != null ? int.tryParse(m.group(1)!) ?? 1 : 1;
  }

  Map<String, String> _headersFor(IptvItem it) {
    final map = <String, String>{};
    final ua = (it.userAgent ?? '').trim().isNotEmpty
        ? it.userAgent!.trim()
        : settings.defaultUserAgent.trim();
    if (ua.isNotEmpty) map['user-agent'] = ua;
    final ref = (it.referer ?? '').trim().isNotEmpty
        ? it.referer!.trim()
        : (settings.defaultReferer ?? '').trim();
    if (ref.isNotEmpty) map['referer'] = ref;
    final hj = (it.headersJson ?? '').trim();
    if (hj.isNotEmpty) {
      try {
        final m = Map<String, dynamic>.from(json.decode(hj) as Map);
        m.forEach((k, v) {
          final key = k.toString();
          final val = v?.toString() ?? '';
          if (val.isNotEmpty) map[key] = val;
        });
      } catch (_) {}
    }
    return map;
  }

  void _openSingle(IptvItem it) {
    final url = (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistPlayerPage(
          title: widget.seriesKey,
          playlist: [
            EpisodePlay(title: it.name, url: url, headers: _headersFor(it)),
          ],
          startIndex: 0,
        ),
      ),
    );
  }

  void _playAllSeason(int seasonIndex) {
    final season = _seasons[seasonIndex];
    final eps = _bySeason[season]!;
    final list = eps
        .map(
          (it) => EpisodePlay(
            title: it.name,
            url: (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl,
            headers: _headersFor(it),
          ),
        )
        .toList(growable: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistPlayerPage(
          title: '${widget.seriesKey} — S$season',
          playlist: list,
          startIndex: 0,
        ),
      ),
    );
  }

  void _playAllSeries() {
    final list = widget.episodes
        .map(
          (it) => EpisodePlay(
            title: it.name,
            url: (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl,
            headers: _headersFor(it),
          ),
        )
        .toList(growable: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PlaylistPlayerPage(
          title: widget.seriesKey,
          playlist: list,
          startIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final poster = widget.episodes.firstWhere(
      (it) => (it.logo ?? '').isNotEmpty,
      orElse: () => widget.episodes.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.seriesKey,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton.icon(
            onPressed: _playAllSeries,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Tout lire'),
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          controller: _tabs,
          tabs: _seasons.map((s) => Tab(text: 'S$s')).toList(),
        ),
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 6,
            child: Stack(
              fit: StackFit.expand,
              children: [
                (poster.logo ?? '').isNotEmpty
                    ? Image.network(
                        poster.logo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF111111)),
                      )
                    : const ColoredBox(color: Color(0xFF111111)),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: FilledButton.icon(
                    onPressed: _playAllSeries,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Lire la série'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: _seasons.map((s) {
                final eps = _bySeason[s]!;
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: eps.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final it = eps[i];
                    final epNum = _parseEpisode(it.name);
                    return ListTile(
                      leading: CircleAvatar(child: Text('$epNum')),
                      title: Text(
                        it.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(it.groupTitle ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle),
                        onPressed: () => _openSingle(it),
                      ),
                      onTap: () => _openSingle(it),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _playAllSeason(_tabs.index),
        icon: const Icon(Icons.queue_play_next),
        label: const Text('Lire saison'),
      ),
    );
  }
}
