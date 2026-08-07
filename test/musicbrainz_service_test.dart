import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ganne/data/local/database.dart';
import 'package:ganne/services/download/download_service.dart';
import 'package:ganne/services/metadata/musicbrainz_service.dart';
import 'package:ganne/services/metadata/resolved_track_metadata.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('MusicBrainzService', () {
    test(
      'resolves an exact ISRC and caches original release artwork',
      () async {
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          if (request.url.host == 'coverartarchive.org') {
            return http.Response.bytes(
              const [0xff, 0xd8, 0xff, 0xe0, 1, 2, 3, 4],
              200,
              headers: const {'content-type': 'image/jpeg'},
            );
          }
          if (request.url.path == '/ws/2/recording') {
            expect(request.url.queryParameters['query'], 'isrc:USAAA0000001');
            return _jsonResponse({
              'recordings': [
                {
                  ..._recording(
                    id: 'recording-1',
                    isrc: 'USAAA0000001',
                    title: 'Canonical Track',
                  ),
                  'releases': [
                    {
                      'id': 'release-1',
                      'title': 'Canonical Album',
                      'date': '2024-05-01',
                      'status': 'Official',
                      'artist-credit': _artistCredit(
                        'Album Artist',
                        'album-artist-1',
                      ),
                      'release-group': {
                        'id': 'release-group-1',
                        'primary-type': 'Album',
                      },
                      'media': [
                        {'position': 1, 'track-count': 8},
                        {'position': 2, 'track-count': 10},
                      ],
                    },
                  ],
                },
              ],
            });
          }
          if (request.url.path == '/ws/2/release/release-1') {
            return _jsonResponse(
              _release(
                id: 'release-1',
                barcode: '123456789012',
                tracks: [
                  _releaseTrack(
                    id: 'release-track-1',
                    position: 3,
                    recording: _recording(
                      id: 'recording-1',
                      isrc: 'USAAA0000001',
                      title: 'Canonical Track',
                    ),
                  ),
                ],
                discNumber: 2,
                totalDiscs: 2,
              ),
            );
          }
          throw StateError('Unexpected request: ${request.url}');
        });
        final service = MusicBrainzService(
          client: client,
          minimumRequestInterval: Duration.zero,
        );

        final metadata = await service.resolveTrack(
          isrc: 'us-aaa-00-00001',
          title: 'Canonical Track',
          artist: 'Track Artist',
          album: 'Canonical Album',
          albumArtist: 'Album Artist',
          durationSeconds: 201,
          year: 2024,
          trackNumber: 3,
          discNumber: 2,
          totalTracks: 10,
          totalDiscs: 2,
        );
        final cachedMetadata = await service.resolveTrack(
          isrc: 'us-aaa-00-00001',
          title: 'Canonical Track',
          artist: 'Track Artist',
          album: 'Canonical Album',
          albumArtist: 'Album Artist',
          durationSeconds: 201,
          year: 2024,
          trackNumber: 3,
          discNumber: 2,
          totalTracks: 10,
          totalDiscs: 2,
        );

        expect(identical(metadata, cachedMetadata), isTrue);
        expect(metadata, isNotNull);
        expect(metadata!.recordingId, 'recording-1');
        expect(metadata.releaseTrackId, 'release-track-1');
        expect(metadata.releaseId, 'release-1');
        expect(metadata.releaseGroupId, 'release-group-1');
        expect(metadata.trackNumber, 3);
        expect(metadata.totalTracks, 10);
        expect(metadata.discNumber, 2);
        expect(metadata.totalDiscs, 2);
        expect(metadata.label, 'Example Label');
        expect(metadata.catalogNumber, 'CAT-001');
        expect(metadata.releaseType, 'Album; Compilation');
        expect(metadata.hasFrontCover, isTrue);

        final cover = await service.fetchCoverArt(metadata.releaseId!);
        final cachedCover = await service.fetchCoverArt(metadata.releaseId!);
        expect(identical(cover, cachedCover), isTrue);
        expect(cover?.mimeType, 'image/jpeg');
        expect(cover?.bytes.length, 8);

        expect(
          requests.where((request) => request.url.host == 'musicbrainz.org'),
          hasLength(2),
        );
        final coverRequests = requests
            .where((request) => request.url.host == 'coverartarchive.org')
            .toList();
        expect(coverRequests, hasLength(1));
        expect(coverRequests.single.url.path, '/release/release-1/front');
        expect(coverRequests.single.url.path, isNot(contains('1200')));
        for (final request in requests) {
          expect(_header(request, 'user-agent'), contains('Ganne/1.0.0'));
        }
      },
    );

    test(
      'shares exact UPC and release lookups and rejects ISRC drift',
      () async {
        final requests = <http.Request>[];
        final release = _release(
          id: 'release-1',
          barcode: '123456789012',
          tracks: [
            _releaseTrack(
              id: 'release-track-1',
              position: 1,
              recording: _recording(
                id: 'recording-1',
                isrc: 'USAAA0000001',
                title: 'Track One',
              ),
            ),
            _releaseTrack(
              id: 'release-track-2',
              position: 2,
              recording: _recording(
                id: 'recording-2',
                isrc: 'USAAA0000002',
                title: 'Track Two',
              ),
            ),
          ],
        );
        final client = MockClient((request) async {
          requests.add(request);
          if (request.url.path == '/ws/2/release') {
            expect(
              request.url.queryParameters['query'],
              'barcode:123456789012',
            );
            return _jsonResponse({
              'releases': [
                {
                  'id': 'release-1',
                  'title': 'Canonical Album',
                  'barcode': '123456789012',
                },
              ],
            });
          }
          if (request.url.path == '/ws/2/release/release-1') {
            return _jsonResponse(release);
          }
          if (request.url.path == '/ws/2/recording') {
            return _jsonResponse({'recordings': []});
          }
          throw StateError('Unexpected request: ${request.url}');
        });
        final service = MusicBrainzService(
          client: client,
          minimumRequestInterval: Duration.zero,
        );

        final results = await Future.wait([
          service.resolveTrack(
            isrc: 'USAAA0000001',
            title: 'Track One',
            artist: 'Track Artist',
            album: 'Canonical Album',
            barcode: '0123456789012',
          ),
          service.resolveTrack(
            isrc: 'USAAA0000002',
            title: 'Track Two',
            artist: 'Track Artist',
            album: 'Canonical Album',
            barcode: '123456789012',
          ),
        ]);
        expect(results.map((result) => result?.trackNumber), [1, 2]);

        final mismatch = await service.resolveTrack(
          isrc: 'USAAA0000003',
          title: 'Track One',
          artist: 'Track Artist',
          album: 'Canonical Album',
          barcode: '123456789012',
        );
        expect(mismatch, isNull);
        expect(
          requests.where((request) => request.url.path == '/ws/2/release'),
          hasLength(1),
        );
        expect(
          requests.where(
            (request) => request.url.path == '/ws/2/release/release-1',
          ),
          hasLength(1),
        );
      },
    );

    test('rejects weak title containment without an ISRC', () async {
      final service = MusicBrainzService(
        client: MockClient(
          (_) async => _jsonResponse({
            'recordings': [
              {
                ..._recording(
                  id: 'wrong-recording',
                  isrc: null,
                  title: 'Someone',
                ),
                'isrcs': <String>[],
                'releases': <Object>[],
              },
            ],
          }),
        ),
        minimumRequestInterval: Duration.zero,
      );

      final metadata = await service.resolveTrack(
        title: 'One',
        artist: 'Track Artist',
        album: 'Canonical Album',
      );
      expect(metadata, isNull);
    });

    test(
      'serializes MusicBrainz requests at the configured interval',
      () async {
        const interval = Duration(milliseconds: 40);
        final stopwatch = Stopwatch()..start();
        final starts = <Duration>[];
        final service = MusicBrainzService(
          client: MockClient((_) async {
            starts.add(stopwatch.elapsed);
            return _jsonResponse({'recordings': []});
          }),
          minimumRequestInterval: interval,
        );

        await Future.wait([
          service.resolveTrack(
            isrc: 'USAAA0000001',
            title: 'Track One',
            artist: 'Track Artist',
            album: 'Album',
          ),
          service.resolveTrack(
            isrc: 'USAAA0000002',
            title: 'Track Two',
            artist: 'Track Artist',
            album: 'Album',
          ),
        ]);

        expect(starts, hasLength(2));
        expect(starts[1] - starts[0], greaterThanOrEqualTo(interval));
      },
    );
  });

  group('ResolvedTrackMetadata', () {
    test('retains Qobuz fallback values when no confident match exists', () {
      final task = _downloadTask();
      final metadata = ResolvedTrackMetadata(task: task);

      expect(metadata.title, 'Qobuz Track');
      expect(metadata.artist, 'Qobuz Artist');
      expect(metadata.album, 'Qobuz Album');
      expect(metadata.trackNumber, 2);
      expect(metadata.totalTracks, 12);
      expect(metadata.flacTags['ISRC'], 'USQOB0000001');
      expect(metadata.flacTags['LABEL'], 'Qobuz Label');
      expect(metadata.flacTags, isNot(contains('MUSICBRAINZ_TRACKID')));
      expect(identical(metadata.persistedTask, task), isTrue);
      expect(
        DownloadService.fullResolutionCoverUrl(
          'https://static.qobuz.com/images/covers/abc/600.jpg',
        ),
        'https://static.qobuz.com/images/covers/abc/org.jpg',
      );
    });

    test('builds complete Picard tags and persisted release metadata', () {
      final metadata = ResolvedTrackMetadata(
        task: _downloadTask(),
        musicBrainz: const MusicBrainzMetadata(
          title: 'Canonical Track',
          artist: 'Canonical Artist',
          album: 'Canonical Album',
          albumArtist: 'Canonical Album Artist',
          date: '2024-05-01',
          originalDate: '2020-02-03',
          genre: 'Alternative',
          isrc: 'USAAA0000001',
          trackNumber: 3,
          totalTracks: 10,
          discNumber: 2,
          totalDiscs: 2,
          recordingId: 'recording-1',
          releaseTrackId: 'release-track-1',
          releaseId: 'release-1',
          releaseGroupId: 'release-group-1',
          artistIds: ['artist-1'],
          albumArtistIds: ['album-artist-1'],
          barcode: '123456789012',
          label: 'Example Label',
          catalogNumber: 'CAT-001',
          releaseCountry: 'GB',
          releaseStatus: 'Official',
          releaseType: 'Album; Compilation',
          hasFrontCover: true,
        ),
      );

      expect(metadata.flacTags, {
        'TITLE': 'Canonical Track',
        'ARTIST': 'Canonical Artist',
        'ALBUM': 'Canonical Album',
        'ALBUMARTIST': 'Canonical Album Artist',
        'ALBUM_ARTIST': 'Canonical Album Artist',
        'TRACKNUMBER': '3',
        'TRACKTOTAL': '10',
        'TOTALTRACKS': '10',
        'DISCNUMBER': '2',
        'DISCTOTAL': '2',
        'TOTALDISCS': '2',
        'DATE': '2024-05-01',
        'ORIGINALDATE': '2020-02-03',
        'GENRE': 'Alternative',
        'ISRC': 'USAAA0000001',
        'COPYRIGHT': 'Qobuz Copyright',
        'LABEL': 'Example Label',
        'BARCODE': '123456789012',
        'CATALOGNUMBER': 'CAT-001',
        'VERSION': 'Deluxe',
        'MUSICBRAINZ_TRACKID': 'recording-1',
        'MUSICBRAINZ_RELEASETRACKID': 'release-track-1',
        'MUSICBRAINZ_ALBUMID': 'release-1',
        'MUSICBRAINZ_RELEASEGROUPID': 'release-group-1',
        'MUSICBRAINZ_ARTISTID': 'artist-1',
        'MUSICBRAINZ_ALBUMARTISTID': 'album-artist-1',
        'RELEASECOUNTRY': 'GB',
        'RELEASESTATUS': 'Official',
        'RELEASETYPE': 'Album; Compilation',
      });

      final persisted = metadata.persistedTask;
      expect(persisted.trackTitle, 'Canonical Track');
      expect(persisted.year, 2024);
      expect(persisted.catalogNumber, 'CAT-001');
      expect(persisted.releaseDate, '2024-05-01');
      expect(persisted.originalReleaseDate, '2020-02-03');
      expect(persisted.musicBrainzRecordingId, 'recording-1');
      expect(persisted.musicBrainzReleaseTrackId, 'release-track-1');
      expect(persisted.musicBrainzReleaseId, 'release-1');
      expect(persisted.musicBrainzReleaseGroupId, 'release-group-1');
      expect(persisted.musicBrainzArtistIds, 'artist-1');
      expect(persisted.musicBrainzAlbumArtistIds, 'album-artist-1');
    });
  });
}

http.Response _jsonResponse(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: const {'content-type': 'application/json'},
);

String? _header(http.Request request, String name) {
  final normalizedName = name.toLowerCase();
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == normalizedName) return entry.value;
  }
  return null;
}

List<Map<String, Object>> _artistCredit(String name, String id) => [
  {
    'name': name,
    'artist': {'id': id, 'name': name},
  },
];

Map<String, Object?> _recording({
  required String id,
  required String? isrc,
  required String title,
}) => {
  'id': id,
  'title': title,
  'length': 201000,
  'score': 100,
  'isrcs': isrc == null ? <String>[] : [isrc],
  'artist-credit': _artistCredit('Track Artist', 'artist-1'),
  'genres': [
    {'name': 'Rock', 'count': 10},
  ],
};

Map<String, Object?> _releaseTrack({
  required String id,
  required int position,
  required Map<String, Object?> recording,
}) => {
  'id': id,
  'position': position,
  'title': recording['title'],
  'length': recording['length'],
  'artist-credit': _artistCredit('Track Artist', 'artist-1'),
  'recording': recording,
};

Map<String, Object?> _release({
  required String id,
  required String barcode,
  required List<Map<String, Object?>> tracks,
  int discNumber = 1,
  int totalDiscs = 1,
}) {
  final media = <Map<String, Object?>>[];
  for (var position = 1; position <= totalDiscs; position++) {
    media.add({
      'position': position,
      'track-count': position == discNumber ? 10 : 8,
      'tracks': position == discNumber ? tracks : <Object>[],
    });
  }
  return {
    'id': id,
    'title': 'Canonical Album',
    'date': '2024-05-01',
    'country': 'GB',
    'status': 'Official',
    'barcode': barcode,
    'artist-credit': _artistCredit('Album Artist', 'album-artist-1'),
    'release-group': {
      'id': 'release-group-1',
      'first-release-date': '2020-02-03',
      'primary-type': 'Album',
      'secondary-types': ['Compilation'],
    },
    'label-info': [
      {
        'catalog-number': 'CAT-001',
        'label': {'name': 'Example Label'},
      },
    ],
    'media': media,
    'cover-art-archive': {'front': true},
  };
}

DownloadTask _downloadTask() => const DownloadTask(
  id: 1,
  trackId: 10,
  trackTitle: 'Qobuz Track',
  albumTitle: 'Qobuz Album',
  artistName: 'Qobuz Artist',
  albumArtist: 'Qobuz Album Artist',
  trackVersion: 'Deluxe',
  isrc: 'USQOB0000001',
  trackNumber: 2,
  discNumber: 1,
  totalTracks: 12,
  totalDiscs: 1,
  durationSeconds: 200,
  year: 2023,
  genre: 'Pop',
  copyright: 'Qobuz Copyright',
  label: 'Qobuz Label',
  barcode: '999999999999',
  coverUrl: 'https://static.qobuz.com/images/covers/abc/600.jpg',
  quality: '27',
  totalBytes: 0,
  downloadedBytes: 0,
  status: 'pending',
  addedAt: 0,
);
