import 'package:flutter/material.dart';
import '../../../../core/settings.dart';
import '../../../widgets/cnd_video_player.dart';

class MoviePlayerPage extends StatelessWidget {
  final String title;
  final String url;

  const MoviePlayerPage({super.key, required this.title, required this.url});

  Map<String, String> _headers() {
    final h = <String, String>{};
    final ua = settings.defaultUserAgent.trim();
    if (ua.isNotEmpty) h['user-agent'] = ua;
    final ref = (settings.defaultReferer ?? '').trim();
    if (ref.isNotEmpty) h['referer'] = ref;
    return h;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CndVideoPlayer(
              url: url,
              headers: _headers(),
              autoPlay: true,
            ),
          ),
        ),
      ),
    );
  }
}
