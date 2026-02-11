import 'package:cnd_iptv/data/iptv_models.dart';
import 'package:cnd_iptv/data/iptv_repository.dart';
import 'package:cnd_iptv/viewmodels/iptv_vm.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Simple Fake implementation to avoid build_runner overhead in this session
class FakeIptvRepository extends Fake implements IptvRepository {
  final List<IptvItem> _items = [];

  FakeIptvRepository() {
    // Seed with some data
    for (var i = 1; i <= 100; i++) {
      _items.add(IptvItem()
        ..id = i
        ..name = 'Item $i'
        ..kind = i % 2 == 0 ? 'movie' : 'live'
        ..groupTitle = i % 3 == 0 ? 'Group A' : 'Group B'
        ..host = 'host${i % 2}.com'
        ..streamUrl = 'http://host${i % 2}.com/stream/$i'
        ..imdbRating = (i % 10).toDouble());
    }
  }

  @override
  Future<List<IptvItem>> findItems({
    required String kind,
    int offset = 0,
    int limit = 50,
    String query = '',
    String? group,
    String? host,
    String sortKey = 'Name',
    bool sortAsc = true,
  }) async {
    // Filter by kind
    var result = _items.where((e) => e.kind == kind).toList();

    // Filter by query
    if (query.isNotEmpty) {
      result = result
          .where((e) =>
              e.name.toLowerCase().contains(query.toLowerCase()) ||
              (e.groupTitle ?? '').toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    // Filter by group
    if (group != null && group.isNotEmpty) {
      result = result.where((e) => e.groupTitle == group).toList();
    }

    // Filter by host
    if (host != null && host.isNotEmpty) {
      result = result.where((e) => e.host == host).toList();
    }

    // Sorting (simplified for test)
    result.sort((a, b) {
      if (sortKey == 'Name') {
        return sortAsc
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name);
      }
      return 0; 
    });

    // Pagination
    if (offset >= result.length) return [];
    final end = (offset + limit) > result.length ? result.length : offset + limit;
    return result.sublist(offset, end);
  }

  @override
  Future<List<String>> getGroups(String kind) async {
    return _items
        .where((e) => e.kind == kind)
        .map((e) => e.groupTitle ?? '')
        .toSet()
        .toList();
  }

  @override
  Future<List<String>> getHosts(String kind) async {
    return _items
        .where((e) => e.kind == kind)
        .map((e) => e.host ?? '')
        .toSet()
        .toList();
  }
}

void main() {
  group('PaginatedIptvNotifier', () {
    late FakeIptvRepository repo;
    late PaginatedIptvNotifier notifier;

    setUp(() {
      repo = FakeIptvRepository();
      // 'movie' items are even numbers: 2, 4, ... 100 (50 items total)
      notifier = PaginatedIptvNotifier(repo, 'movie');
    });

    test('initial state loads items', () async {
      // Allow async initial load to complete
      await Future.delayed(Duration.zero);
      
      expect(notifier.state.items.length, 50); // limit is 50, total 50 movies
      expect(notifier.state.items.first.name, 'Item 10'); // Alphabetical sort: 10 comes before 2
      expect(notifier.state.isLoading, false);
      expect(notifier.state.hasMore, true); 
    });

    test('pagination loads next page', () async {
       await Future.delayed(Duration.zero);
       expect(notifier.state.items.length, 50);
       
       // Try load next
       await notifier.loadNext();
       // Should fetch offset 50, which returns empty
       expect(notifier.state.items.length, 50);
       expect(notifier.state.hasMore, false);
    });

    test('filtering by query resets and reloads', () async {
      await Future.delayed(Duration.zero);
      
      // 'Item 2' exists. 'Item 4' exists.
      await notifier.setQuery('Item 2');
      
      expect(notifier.state.items.length, greaterThan(0)); // Multiple items might match 'Item 2'
      expect(notifier.state.items.isNotEmpty, true);
      expect(notifier.state.query, 'Item 2');
      expect(notifier.state.offset, notifier.state.items.length);
    });

    test('filtering by group', () async {
      await Future.delayed(Duration.zero);
      // Movies are even: 2 (Group B), 4 (Group B), 6 (Group A) ...
      // item i: i%3==0 -> Group A.
      // i=6: movie, Group A.
      await notifier.setGroup('Group A');
      
      expect(notifier.state.group, 'Group A');
      expect(notifier.state.items.any((e) => e.groupTitle != 'Group A'), false);
    });
  });
}
