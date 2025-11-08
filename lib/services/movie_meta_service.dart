import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MovieSynopsis {
  final String title;
  final String? year;
  final String? plot;
  final String? poster; // URL
  final List<String> genres;
  final String? runtime;
  final String? rating; // IMDb rating

  MovieSynopsis({
    required this.title,
    this.year,
    this.plot,
    this.poster,
    this.genres = const [],
    this.runtime,
    this.rating,
  });

  factory MovieSynopsis.fromOmdb(Map<String, dynamic> j) {
    String? toNull(String v) => (v.isEmpty || v == 'N/A') ? null : v;

    return MovieSynopsis(
      title: j['Title'] ?? '',
      year: toNull(j['Year'] ?? ''),
      plot: toNull(j['Plot'] ?? ''),
      poster: toNull(j['Poster'] ?? ''),
      genres: (j['Genre'] as String? ?? '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && e != 'N/A')
          .toList(),
      runtime: toNull(j['Runtime'] ?? ''),
      rating: toNull(j['imdbRating'] ?? ''),
    );
  }
}

class MovieMetaService {
  final Dio _dio;
  final String _omdbKey;

  MovieMetaService(this._dio, this._omdbKey);

  // Nettoie les titres IPTV: supprime [tags], (année), résolutions, codecs, etc.
  @visibleForTesting
  String normalizeTitle(String raw) {
    var t = raw;

    // Retirer contenus entre [] () {}
    t = t.replaceAll(RegExp(r'\[[^\]]*\]'), '');
    t = t.replaceAll(RegExp(r'\([^\)]*\)'), '');
    t = t.replaceAll(RegExp(r'\{[^\}]*\}'), '');

    // Retirer résolutions / codecs fréquents
    t = t.replaceAll(
      RegExp(
        r'\b(2160p|1080p|720p|480p|4k|hdr|dv|hevc|x265|x264|h\.?264|h\.?265)\b',
        caseSensitive: false,
      ),
      '',
    );

    // Couper suffixes après " - " ou " | " s'ils existent
    t = t.split(' | ').first;
    t = t.split(' - ').first;

    // Espace propre
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  Future<MovieSynopsis?> fetchByTitle(String rawTitle) async {
    if (_omdbKey.isEmpty) return null;

    final q = normalizeTitle(rawTitle);
    final r = await _dio.get(
      'https://www.omdbapi.com/',
      queryParameters: {'t': q, 'apikey': _omdbKey, 'plot': 'full'},
      options: Options(
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 8),
      ),
    );

    final data = r.data;
    if (data is Map && (data['Response'] == 'True')) {
      return MovieSynopsis.fromOmdb(Map<String, dynamic>.from(data));
    }
    return null;
  }
}

// ----- Providers -----

final _dioForMetaProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 12),
      headers: {'accept': 'application/json', 'user-agent': 'cnd-dl/1.0'},
    ),
  );
});

/// Choisis l’une des 2 options:
/// 1) --dart-define=OMDB_API_KEY=XXXX (recommandé)
/// 2) remplace la valeur par ta clé en dur (moins bien)
final _omdbKeyProvider = Provider<String>((ref) {
  const fromDefine = String.fromEnvironment('OMDB_API_KEY', defaultValue: '');
  return fromDefine; // ou retourne une clé en dur si besoin temporaire
});

final movieMetaServiceProvider = Provider<MovieMetaService>((ref) {
  return MovieMetaService(
    ref.read(_dioForMetaProvider),
    ref.read(_omdbKeyProvider),
  );
});

/// FutureProvider family: résume par titre
final movieSynopsisProvider = FutureProvider.family<MovieSynopsis?, String>((
  ref,
  rawTitle,
) async {
  return ref.read(movieMetaServiceProvider).fetchByTitle(rawTitle);
});
