import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganne/data/local/database.dart';
import 'package:ganne/services/player/player_service.dart';
import 'package:ganne/ui/widgets/full_player.dart';

void main() {
  final tracks = [
    _track(
      id: 1,
      title: 'A Long Track Title That Needs More Than One Line',
      artist: 'Test Artist',
      album: 'Test Album',
    ),
    _track(
      id: 2,
      title: 'Next Track',
      artist: 'Second Artist',
      album: 'Second Album',
    ),
  ];

  Future<void> pumpPlayer(
    WidgetTester tester,
    Size size, {
    List<DownloadTask>? playbackQueue,
  }) async {
    final testQueue = playbackQueue ?? tracks;
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioPlayerProvider.overrideWith(
            () => _TestAudioPlayerNotifier(
              PlaybackState(
                currentTrack: testQueue.first,
                isPlaying: true,
                position: const Duration(minutes: 1, seconds: 12),
                duration: const Duration(minutes: 4, seconds: 8),
                queue: testQueue,
                currentIndex: 0,
                volume: 0.75,
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: FullPlayer())),
      ),
    );
    await tester.pump();
  }

  testWidgets('uses a scroll-safe compact portrait layout', (tester) async {
    await pumpPlayer(tester, const Size(390, 600));

    expect(find.byKey(const ValueKey('full_player_portrait_layout')), findsOne);
    expect(find.byKey(const ValueKey('full_player_volume')), findsNothing);
    expect(find.byTooltip('Pause'), findsOne);
    expect(find.text('Test Artist'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps full controls on a regular portrait viewport', (
    tester,
  ) async {
    await pumpPlayer(tester, const Size(390, 844));

    expect(find.byKey(const ValueKey('full_player_portrait_layout')), findsOne);
    expect(find.byKey(const ValueKey('full_player_volume')), findsOne);
    expect(find.byKey(const ValueKey('full_player_seek')), findsOne);

    await tester.tap(find.byTooltip('Show queue'));
    await tester.pumpAndSettle();

    expect(find.text('Queue'), findsOne);
    expect(find.byKey(const ValueKey('queue_list_view')), findsOne);
    expect(find.text('Next Track'), findsOne);
    expect(find.byKey(const ValueKey('queue_end_state')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('labels the end of a current-only playback queue', (
    tester,
  ) async {
    await pumpPlayer(
      tester,
      const Size(390, 844),
      playbackQueue: [tracks.first],
    );

    await tester.tap(find.byTooltip('Show queue'));
    await tester.pumpAndSettle();

    expect(find.text('1 track'), findsOne);
    expect(find.byKey(const ValueKey('queue_end_state')), findsOne);
    expect(find.text('End of queue'), findsOne);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses the two-column layout in a wide viewport', (tester) async {
    await pumpPlayer(tester, const Size(800, 420));

    expect(find.byKey(const ValueKey('full_player_wide_layout')), findsOne);
    expect(find.byKey(const ValueKey('full_player_volume')), findsNothing);
    expect(find.text('Test Album • 2025'), findsOne);
    expect(tester.takeException(), isNull);
  });
}

DownloadTask _track({
  required int id,
  required String title,
  required String artist,
  required String album,
}) {
  return DownloadTask(
    id: id,
    trackId: id,
    trackTitle: title,
    albumTitle: album,
    artistName: artist,
    year: 2025,
    coverUrl: '',
    quality: '27',
    totalBytes: 0,
    downloadedBytes: 0,
    status: 'library',
    savePath: 'track-$id.flac',
    addedAt: id,
  );
}

class _TestAudioPlayerNotifier extends AudioPlayerNotifier {
  _TestAudioPlayerNotifier(this.initialState);

  final PlaybackState initialState;

  @override
  PlaybackState build() => initialState;
}
