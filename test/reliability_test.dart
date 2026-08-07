import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ganne/core/utils/flac_tagger.dart';
import 'package:ganne/data/local/database.dart';
import 'package:ganne/data/models/qobuz_models.dart';
import 'package:ganne/services/download/download_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('DownloadService file helpers', () {
    test('sanitizes unsafe output path components', () {
      expect(
        DownloadService.formatFileName('..', '../', 'live:/', 'flac'),
        'Unknown Artist - Unknown Title (live).flac',
      );
      expect(
        DownloadService.formatFileName('CON', 'Track. ', null, 'flac'),
        'Unknown Artist - Track.flac',
      );
      expect(
        DownloadService.fullResolutionCoverUrl(
          'https://static.qobuz.com/images/covers/ab/cd/600.jpg',
        ),
        'https://static.qobuz.com/images/covers/ab/cd/org.jpg',
      );
    });

    test('uses MIME parameters and validates known audio signatures', () {
      expect(
        DownloadService.extensionFromMime('audio/flac; charset=binary', '5'),
        '.flac',
      );
      expect(
        DownloadService.detectExtensionFromBytes(
          Uint8List.fromList([0x66, 0x4C, 0x61, 0x43]),
        ),
        '.flac',
      );
      expect(
        DownloadService.detectExtensionFromBytes(
          Uint8List.fromList([0xFF, 0xF1]),
        ),
        '.aac',
      );
      expect(
        DownloadService.detectExtensionFromBytes(
          Uint8List.fromList([0xFF, 0xFB]),
        ),
        '.mp3',
      );
      expect(
        DownloadService.detectExtensionFromBytes(
          Uint8List.fromList([
            0x52,
            0x49,
            0x46,
            0x46,
            0,
            0,
            0,
            0,
            0x41,
            0x56,
            0x49,
            0x20,
          ]),
        ),
        isNull,
      );
      expect(
        DownloadService.detectExtensionFromBytes(Uint8List.fromList([0, 1, 2])),
        isNull,
      );
    });

    test('uses the performer as the track artist', () {
      final album = QobuzAlbum(
        'album-1',
        null,
        'Compilation',
        null,
        null,
        null,
        null,
        null,
        QobuzArtist(1, 'Various Artists', null, null),
        [QobuzArtist(1, 'Various Artists', null, null)],
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
      );
      final track = QobuzTrack(
        1,
        'Featured Track',
        null,
        null,
        null,
        1,
        1,
        null,
        null,
        null,
        null,
        null,
        album,
        QobuzArtist(2, 'Featured Artist', null, null),
      );

      expect(
        DownloadService.artistNameForTrack(track, album: album),
        'Featured Artist',
      );
    });

    test('builds organized and flat track directories', () {
      expect(
        DownloadService.relativeTrackDirectory('Artist', 'Album', flat: false),
        p.join('Artist', 'Album'),
      );
      expect(
        DownloadService.relativeTrackDirectory('Artist', 'Album', flat: true),
        isEmpty,
      );
    });
  });

  test('requeues downloads interrupted by process termination', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.insertTask(
      DownloadTasksCompanion.insert(
        trackId: 1,
        trackTitle: 'Track',
        albumTitle: 'Album',
        artistName: 'Artist',
        coverUrl: '',
        quality: '6',
        addedAt: 1,
      ),
    );
    final task = (await db.getAllTasks()).single;
    await db.updateTask(task.copyWith(status: 'downloading'));

    expect(await db.requeueInterruptedTasks(), 1);
    expect((await db.getAllTasks()).single.status, 'pending');
  });

  test('streams FLAC audio while replacing metadata', () async {
    final directory = await Directory.systemTemp.createTemp('ganne-flac-test-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}track.flac');
    final audio = Uint8List.fromList([1, 2, 3, 4]);
    final source = BytesBuilder()
      ..add(const [0x66, 0x4C, 0x61, 0x43])
      ..add(const [0x80, 0x00, 0x00, 0x22])
      ..add(Uint8List(34))
      ..add(audio);
    await file.writeAsBytes(source.toBytes());

    await FlacTagger.writeTags(
      filePath: file.path,
      tags: {'TITLE': 'Tagged Track'},
      coverBytes: Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
      ]),
      coverMimeType: 'image/png',
    );

    final result = await file.readAsBytes();
    expect(result.sublist(result.length - audio.length), audio);
    expect(
      utf8.decode(result, allowMalformed: true),
      contains('TITLE=Tagged Track'),
    );
    expect(utf8.decode(result, allowMalformed: true), contains('image/png'));
  });
}
