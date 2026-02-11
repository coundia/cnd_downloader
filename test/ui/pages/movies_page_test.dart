import 'package:cnd_iptv/data/iptv_models.dart';
import 'package:cnd_iptv/data/iptv_repository.dart';
import 'package:cnd_iptv/ui/pages/movies_page.dart';
import 'package:cnd_iptv/viewmodels/iptv_vm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

// Minimal fake repository for UI test
class FakeIptvRepository extends Fake implements IptvRepository {
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
    // Return a few fake items
    final allItems = List.generate(
      5,
      (i) => IptvItem()
        ..id = i
        ..name = 'Movie $i'
        ..kind = 'movie'
        ..groupTitle = 'Action'
        ..host = 'server.com'
        ..streamUrl = 'http://server.com/stream/$i.mp4',
    );

    if (query.isNotEmpty) {
      return allItems.where((e) => e.name.contains(query)).toList();
    }
    
    return allItems;
  }

  @override
  Future<List<String>> getGroups(String kind) async {
    // Return some groups, significantly WITHOUT empty string to test the fix
    return ['Action', 'Comedy', 'Drama'];
  }

  @override
  Future<List<String>> getHosts(String kind) async {
    return ['server.com', 'cdn.net'];
  }
}

void main() {
  testWidgets('MoviesPage renders correctly with filters', (tester) async {
    // 1. Setup overrides
    final fakeRepo = FakeIptvRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iptvRepoProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: MoviesPage(),
        ),
      ),
    );

    // 2. Initial pump
    // The page loads data asynchronously. We need to pump frames.
    await tester.pump(); 
    // Wait for the async gap (FutureBuilders and Notifier logic)
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();

    // 3. Verify
    // Check if app bar exists
    expect(find.text('Movies'), findsOneWidget);

    // Verify we found at least the first item (Movie 0)
    // Note: Movie 4 might be off-screen in default test viewport
    expect(find.text('Movie 0'), findsOneWidget); 
    
    // Check if DropdownButton is present (SearchFilterBar uses them)
    // This confirms the bar was built and didn't crash
    expect(find.byType(DropdownButtonFormField<String>), findsAtLeastNWidgets(1));
  });

  testWidgets('MoviesPage filters list on search', (tester) async {
    final fakeRepo = FakeIptvRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iptvRepoProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: MoviesPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initial state: 5 items (Movie 0 to 4)
    expect(find.text('Movie 0'), findsOneWidget);
    expect(find.text('Movie 4'), findsNothing); // Probably off screen but let's scroll if needed
    // Actually Movie 4 might be visible depending on screen size. Default is 800x600.
    // 5 items take some space. Masonry grid. 
    // Let's rely on finding specific item.
    
    // Find search field
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);

    // Enter "Movie 3"
    await tester.enterText(searchField, 'Movie 3');
    await tester.pump(); // Rebuild with text
    // Debounce is 220ms in SearchFilterBar
    await tester.pump(const Duration(milliseconds: 300)); 
    await tester.pumpAndSettle();

    // Verify we found 2 widgets: input field and the item card
    // Better: Find the card specifically
    final cardFinder = find.descendant(of: find.byType(InkWell), matching: find.text('Movie 3'));
    expect(cardFinder, findsOneWidget);
    
    // Ensure 'Movie 0' is GONE (no card for it)
    final card0 = find.descendant(of: find.byType(InkWell), matching: find.text('Movie 0'));
    expect(card0, findsNothing);
  });

  testWidgets('MoviesPage preserves spaces in search input', (tester) async {
    final fakeRepo = FakeIptvRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iptvRepoProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: MoviesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final searchField = find.byType(TextField);
    
    // Type "Movie " (with space)
    await tester.enterText(searchField, 'Movie ');
    await tester.pump();
    
    // Wait for debounce
    await tester.pump(const Duration(milliseconds: 300));
    // And allow any async state updates to propagate back
    await tester.pumpAndSettle();

    // Verify the text field still contains "Movie "
    final textField = tester.widget<TextField>(searchField);
    expect(textField.controller!.text, 'Movie ');
  });

  testWidgets('MoviesPage shows clear filter button when filters active', (tester) async {
    final fakeRepo = FakeIptvRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          iptvRepoProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: MoviesPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify clear button is hidden initially
    final clearBtn = find.byIcon(Icons.filter_alt_off);
    expect(clearBtn, findsNothing);

    // Open Group Dropdown (first one)
    final dropdowns = find.byType(DropdownButtonFormField<String>);
    await tester.tap(dropdowns.first); 
    await tester.pumpAndSettle();

    // Select "Action" from the menu
    // Target the DropdownMenuItem specifically to avoid tapping content
    final actionItem = find.descendant(
      of: find.byType(DropdownMenuItem<String>), 
      matching: find.text('Action'),
    );
    await tester.tap(actionItem.last); // Use last to pick the one in the topmost route (the open menu) 
    await tester.pumpAndSettle();

    // Verify clear button is now visible
    expect(clearBtn, findsOneWidget);

    // Tap clear button
    await tester.tap(clearBtn);
    await tester.pumpAndSettle();

    // Verify button is gone
    expect(clearBtn, findsNothing);
  });


}
