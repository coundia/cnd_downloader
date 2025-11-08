import '../../../../data/iptv_models.dart';
import 'movies_filter_state.dart';

String _host(String u) {
  try {
    return Uri.parse(u).host;
  } catch (_) {
    return '';
  }
}

void sortMovies(List<IptvItem> list, MoviesSort sort) {
  int ci(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());

  switch (sort) {
    case MoviesSort.nameAsc:
      list.sort((a, b) => ci(a.name, b.name));
      break;
    case MoviesSort.nameDesc:
      list.sort((a, b) => ci(b.name, a.name));
      break;
    case MoviesSort.groupAsc:
      list.sort((a, b) => ci(a.groupTitle ?? '', b.groupTitle ?? ''));
      break;
    case MoviesSort.hostAsc:
      list.sort((a, b) => ci(_host(a.streamUrl), _host(b.streamUrl)));
      break;
  }
}
