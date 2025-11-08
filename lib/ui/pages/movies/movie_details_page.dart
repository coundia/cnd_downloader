import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/iptv_models.dart';
import 'widgets/movie_details_pane.dart';

class MovieDetailsPage extends ConsumerWidget {
  final IptvItem item;
  const MovieDetailsPage({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: MovieDetailsPane(item: item),
    );
  }
}
