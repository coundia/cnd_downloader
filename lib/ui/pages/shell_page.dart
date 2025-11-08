import 'package:flutter/material.dart';
import 'home_page.dart';
import 'tv_page.dart';
import 'movies_page.dart';
import 'series_page.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});
  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [HomePage(), TvPage(), MoviesPage(), SeriesPage()];
    final navItems = const [
      NavigationDestination(icon: Icon(Icons.download), label: 'Downloads'),
      NavigationDestination(icon: Icon(Icons.live_tv), label: 'TV'),
      NavigationDestination(icon: Icon(Icons.local_movies), label: 'Movies'),
      NavigationDestination(
        icon: Icon(Icons.movie_creation_outlined),
        label: 'Series',
      ),
    ];

    return LayoutBuilder(
      builder: (c, bc) {
        final wide = bc.maxWidth >= 900;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (v) => setState(() => index = v),
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.download),
                      label: Text('Downloads'),
                    ),
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
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: pages[index]),
              ],
            ),
          );
        }
        return Scaffold(
          body: pages[index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            destinations: navItems,
            onDestinationSelected: (v) => setState(() => index = v),
          ),
        );
      },
    );
  }
}
