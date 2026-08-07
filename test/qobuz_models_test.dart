import 'package:flutter_test/flutter_test.dart';
import 'package:ganne/data/models/qobuz_models.dart';

void main() {
  test('parses object-shaped artist images and labels in search results', () {
    final results = SearchResults.fromJson({
      'query': 'red velvet',
      'albums': {
        'limit': 1,
        'offset': 0,
        'total': 1,
        'items': [
          {
            'id': 'album-1',
            'title': 'The Album',
            'label': {'name': 'SM Entertainment'},
            'artist': {
              'id': 1,
              'name': 'Red Velvet',
              'image': {
                'small': 'https://example.com/small.jpg',
                'large': 'https://example.com/large.jpg',
              },
            },
          },
        ],
      },
    });

    expect(
      results.albums!.items!.single.artist!.image,
      'https://example.com/large.jpg',
    );
    expect(results.albums!.items!.single.label, 'SM Entertainment');
  });
}
