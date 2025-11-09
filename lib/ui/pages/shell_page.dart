import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'download_page.dart';
import 'tv_page.dart';
import 'movies_page.dart';
import 'series_page.dart';
import 'settings_page.dart';
import '../sources/sources_page.dart';
import '../sources/source_form_page.dart';
import 'about_page.dart';

class ShellPage extends ConsumerStatefulWidget {
  const ShellPage({super.key});
  @override
  ConsumerState<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends ConsumerState<ShellPage> {
  final bucket = PageStorageBucket();
  int index = 0;

  static const int tvIdx = 0;
  static const int moviesIdx = 1;
  static const int seriesIdx = 2;
  static const int sourcesIdx = 3;
  static const int downloadsIdx = 4;
  static const int aboutIdx = 5;
  static const int settingsIdx = 6;

  static const _titles = [
    'TV',
    'Movies',
    'Series',
    'Sources',
    'Downloads',
    'About',
    'Settings',
  ];

  late final List<Widget> pages = const [
    TvPage(key: PageStorageKey('tv')),
    MoviesPage(key: PageStorageKey('movies')),
    SeriesPage(key: PageStorageKey('series')),
    SourcesPage(key: PageStorageKey('sources')),
    HomePage(key: PageStorageKey('downloads')),
    AboutPage(key: PageStorageKey('about')),
    SettingsPage(key: PageStorageKey('settings')),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (c, bc) {
        final wide = bc.maxWidth >= 900;

        final actions = <Widget>[
          if (index == sourcesIdx)
            IconButton(
              tooltip: 'Add source',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SourceFormPage()),
                );
              },
              icon: const Icon(Icons.add_circle),
            ),
        ];

        if (wide) {
          return Scaffold(
            appBar: AppBar(title: Text(_titles[index]), actions: actions),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (v) => setState(() => index = v),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.live_tv),
                      label: Text('TV'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_movies),
                      label: Text('Movies'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.movie_creation_outlined),
                      label: Text('Series'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.playlist_play),
                      label: Text('Sources'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.download),
                      label: Text('Downloads'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.info_outline),
                      label: Text('About'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: PageStorage(
                    bucket: bucket,
                    child: IndexedStack(index: index, children: pages),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(_titles[index]), actions: actions),
          body: PageStorage(
            bucket: bucket,
            child: IndexedStack(index: index, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (v) => setState(() => index = v),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.live_tv), label: 'TV'),
              NavigationDestination(
                icon: Icon(Icons.local_movies),
                label: 'Movies',
              ),
              NavigationDestination(
                icon: Icon(Icons.movie_creation_outlined),
                label: 'Series',
              ),
              NavigationDestination(
                icon: Icon(Icons.playlist_play),
                label: 'Sources',
              ),
              NavigationDestination(
                icon: Icon(Icons.download),
                label: 'Downloads',
              ),
              NavigationDestination(
                icon: Icon(Icons.info_outline),
                label: 'About',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
