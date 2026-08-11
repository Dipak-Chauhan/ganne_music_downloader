import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganne/data/models/qobuz_models.dart';
import 'package:ganne/data/providers/service_providers.dart';
import 'package:ganne/data/secure_storage/secure_storage.dart';
import 'package:ganne/services/api/api_client.dart';
import 'package:ganne/services/api/qobuz_service.dart';
import 'package:ganne/ui/screens/search/search_screen.dart';

void main() {
  late _MemorySecureStorage storage;
  late _FakeQobuzService qobuzService;

  setUp(() {
    storage = _MemorySecureStorage();
    qobuzService = _FakeQobuzService(storage);
  });

  Future<void> pumpSearchScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          secureStorageProvider.overrideWithValue(storage),
          qobuzServiceProvider.overrideWithValue(qobuzService),
        ],
        child: const MaterialApp(home: Scaffold(body: SearchScreen())),
      ),
    );
    await tester.pump();
  }

  testWidgets('empty query opens without starting a search', (tester) async {
    await pumpSearchScreen(tester);

    expect(qobuzService.searchCalls, 0);
    expect(find.text('Search for music to get started'), findsOneWidget);
    expect(find.text('Search Result Album'), findsNothing);
  });

  testWidgets('empty visible query hides previous results', (tester) async {
    await pumpSearchScreen(tester);

    await tester.enterText(find.byType(EditableText), 'query');
    final searchBar = tester.widget<SearchBar>(find.byType(SearchBar));
    searchBar.onSubmitted!('query');
    await tester.pump();

    expect(qobuzService.searchCalls, 1);
    expect(find.text('Search Result Album'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '');
    await tester.pump();

    expect(find.text('Search for music to get started'), findsOneWidget);
    expect(find.text('Search Result Album'), findsNothing);
  });

  testWidgets('opens suggestions anchored to the search field', (tester) async {
    await pumpSearchScreen(tester);

    await tester.enterText(find.byType(EditableText), 'query');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Quick Results'), findsOneWidget);
    expect(find.text('Search Result Album'), findsOneWidget);
  });

  testWidgets('sorts tracks by title without case sensitivity', (tester) async {
    await pumpSearchScreen(tester);

    await tester.enterText(find.byType(EditableText), 'query');
    final searchBar = tester.widget<SearchBar>(find.byType(SearchBar));
    searchBar.onSubmitted!('query');
    await tester.pump();

    await tester.tap(find.text('Tracks'));
    await tester.pump();
    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort by Name'));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('alpha track')).dy,
      lessThan(tester.getTopLeft(find.text('Zulu Track')).dy),
    );
  });

  testWidgets('sorts tracks by release date with unknown dates last', (
    tester,
  ) async {
    await pumpSearchScreen(tester);

    await tester.enterText(find.byType(EditableText), 'query');
    final searchBar = tester.widget<SearchBar>(find.byType(SearchBar));
    searchBar.onSubmitted!('query');
    await tester.pump();

    await tester.tap(find.text('Tracks'));
    await tester.pump();
    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sort by Newest'));
    await tester.pump();

    expect(
      tester.getTopLeft(find.text('Zulu Track')).dy,
      lessThan(tester.getTopLeft(find.text('alpha track')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Unknown Date Track')).dy,
      greaterThan(tester.getTopLeft(find.text('alpha track')).dy),
    );
  });
}

class _MemorySecureStorage extends SecureStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> readKey(String key) async => _values[key];

  @override
  Future<void> writeKey(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<Map<String, String>> readAll() async => Map.of(_values);
}

class _FakeQobuzService extends QobuzService {
  _FakeQobuzService(SecureStorage storage) : super(ApiClient(storage), storage);

  int searchCalls = 0;

  @override
  Future<SearchResults> search(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    searchCalls++;
    return SearchResults.fromJson({
      'query': query,
      'albums': {
        'limit': 1,
        'offset': offset,
        'total': 1,
        'items': [
          {'id': 'album-1', 'title': 'Search Result Album'},
        ],
      },
      'tracks': {
        'limit': 3,
        'offset': offset,
        'total': 3,
        'items': [
          {
            'id': 1,
            'title': 'Zulu Track',
            'album': {
              'id': 'album-1',
              'title': 'Search Result Album',
              'released_at': 1704067200,
            },
          },
          {
            'id': 2,
            'title': 'alpha track',
            'album': {
              'id': 'album-2',
              'title': 'Older Album',
              'released_at': 1577836800,
            },
          },
          {
            'id': 3,
            'title': 'Unknown Date Track',
            'album': {'id': 'album-3', 'title': 'Unknown Date Album'},
          },
        ],
      },
    });
  }
}
