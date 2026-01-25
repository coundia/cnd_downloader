import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final cs = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: CndVideoPlayer(
                      url: url,
                      headers: _headers(),
                      autoPlay: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copier l’URL',
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copiée'),
                        behavior: SnackBarBehavior.floating,
                        showCloseIcon: true,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: Icon(Icons.copy, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
