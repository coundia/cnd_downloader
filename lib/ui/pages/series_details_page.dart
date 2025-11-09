import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/iptv_models.dart';
import '../../core/settings.dart';
import '../../core/paths.dart';
import '../../viewmodels/download_list_vm.dart';
import '../widgets/cnd_video_player.dart';
import 'episodePlay.dart';
import 'playlist_player_page.dart';

class SeriesDetailsPage extends ConsumerStatefulWidget {
  final String seriesKey;
  final List<IptvItem> episodes;
  const SeriesDetailsPage({
    super.key,
    required this.seriesKey,
    required this.episodes,
  });

  @override
  ConsumerState<SeriesDetailsPage> createState() => _SeriesDetailsPageState();
}

class _SeriesDetailsPageState extends ConsumerState<SeriesDetailsPage>
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
    if (ua.isNotEmpty) map['User-Agent'] = ua;
    final refh = (it.referer ?? '').trim().isNotEmpty
        ? it.referer!.trim()
        : (settings.defaultReferer ?? '').trim();
    if (refh.isNotEmpty) map['Referer'] = refh;
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

  String _ffHeadersArg(Map<String, String> h) {
    if (h.isEmpty) return '';
    final buf = StringBuffer();
    var first = true;
    h.forEach((k, v) {
      if (!first) buf.write(r'\r\n');
      buf.write('$k: $v');
      first = false;
    });
    return "-headers '${buf.toString()}'";
  }

  String _safeFileName(String raw) {
    final s = raw
        .replaceAll(RegExp(r'[\/\\:*?"<>|]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return s.isEmpty ? 'video' : s;
  }

  String _ffmpegCmd({
    required String title,
    required String url,
    required Map<String, String> headers,
    String ext = 'mp4',
  }) {
    final hdr = _ffHeadersArg(headers);
    final file = _safeFileName(title);
    final hArg = hdr.isEmpty ? '' : '$hdr ';
    return "ffmpeg -hide_banner -loglevel error ${hArg}-i \"$url\" -c copy \"$file.$ext\"";
  }

  Future<void> _copy(String text, String msg) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _enqueueEpisode(IptvItem it) async {
    final url = (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl;
    final dir = await defaultDownloadDir();
    final h = _headersFor(it);
    await ref
        .read(listVmProvider.notifier)
        .addOnly(
          url,
          dir,
          referer: h['Referer'],
          userAgent: h['User-Agent'],
          fileName: it.name,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Ajouté aux téléchargements')));
  }

  Future<void> _enqueueSeason(int seasonIndex) async {
    final season = _seasons[seasonIndex];
    final eps = _bySeason[season]!;
    final dir = await defaultDownloadDir();
    for (final it in eps) {
      final url = (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl;
      final h = _headersFor(it);
      await ref
          .read(listVmProvider.notifier)
          .addOnly(
            url,
            dir,
            referer: h['Referer'],
            userAgent: h['User-Agent'],
            fileName: it.name,
          );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('S$season ajoutée aux téléchargements')),
    );
  }

  Future<void> _enqueueSeries() async {
    final dir = await defaultDownloadDir();
    for (final it in widget.episodes) {
      final url = (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl;
      final h = _headersFor(it);
      await ref
          .read(listVmProvider.notifier)
          .addOnly(
            url,
            dir,
            referer: h['Referer'],
            userAgent: h['User-Agent'],
            fileName: it.name,
          );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Série ajoutée aux téléchargements')),
    );
  }

  void _copyEpisodeCmd(IptvItem it) {
    final url = (it.realUrl ?? '').isNotEmpty ? it.realUrl! : it.streamUrl;
    final cmd = _ffmpegCmd(title: it.name, url: url, headers: _headersFor(it));
    _copy(cmd, 'Commande ffmpeg copiée');
  }

  void _copySeasonCmd(int seasonIndex) {
    final season = _seasons[seasonIndex];
    final eps = _bySeason[season]!;
    final lines = eps
        .map((it) {
          final url = (it.realUrl ?? '').isNotEmpty
              ? it.realUrl!
              : it.streamUrl;
          return _ffmpegCmd(title: it.name, url: url, headers: _headersFor(it));
        })
        .join('\n');
    _showCommandsDialog(title: 'Télécharger S$season', commands: lines);
  }

  void _copySeriesCmd() {
    final lines = widget.episodes
        .map((it) {
          final url = (it.realUrl ?? '').isNotEmpty
              ? it.realUrl!
              : it.streamUrl;
          return _ffmpegCmd(title: it.name, url: url, headers: _headersFor(it));
        })
        .join('\n');
    _showCommandsDialog(title: 'Télécharger toute la série', commands: lines);
  }

  void _showCommandsDialog({required String title, required String commands}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(child: SelectableText(commands)),
        ),
        actions: [
          TextButton(
            onPressed: () => _copy(commands, 'Commandes copiées'),
            child: const Text('Tout copier'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
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
          IconButton(
            tooltip: 'Télécharger la série',
            onPressed: _enqueueSeries,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Copier commandes série',
            onPressed: _copySeriesCmd,
            icon: const Icon(Icons.copy_all),
          ),
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
                  left: 12,
                  bottom: 12,
                  child: FilledButton.tonalIcon(
                    onPressed: () => _enqueueSeason(_tabs.index),
                    icon: const Icon(Icons.download),
                    label: const Text('DL saison'),
                  ),
                ),
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
                      trailing: Wrap(
                        spacing: 6,
                        children: [
                          IconButton(
                            tooltip: 'Télécharger',
                            icon: const Icon(Icons.download),
                            onPressed: () => _enqueueEpisode(it),
                          ),
                          IconButton(
                            tooltip: 'Copier commande',
                            icon: const Icon(Icons.file_copy),
                            onPressed: () => _copyEpisodeCmd(it),
                          ),
                          IconButton(
                            icon: const Icon(Icons.play_circle),
                            tooltip: 'Lire',
                            onPressed: () => _openSingle(it),
                          ),
                        ],
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
