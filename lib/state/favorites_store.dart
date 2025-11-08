import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final favoritesProvider =
    StateNotifierProvider<FavoritesController, Set<int>>(
  (ref) => FavoritesController()..load(),
);

class FavoritesController extends StateNotifier<Set<int>> {
  FavoritesController() : super(<int>{});

  static const _key = 'tv.favorites.ids'; // sauvegarde en StringList

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    state = raw.map(int.parse).toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      state.map((e) => e.toString()).toList(growable: false),
    );
  }

  Future<void> toggle(int id) async {
    final next = state.contains(id)
        ? (state.toSet()..remove(id))
        : (state.toSet()..add(id));
    state = next;
    await _save();
  }

  bool isFav(int id) => state.contains(id);
}
