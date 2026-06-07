import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/local/database.dart';
import '../../data/providers/service_providers.dart';

class PlaybackState {
  final DownloadTask? currentTrack;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final List<DownloadTask> queue;
  final int currentIndex;
  final bool isShuffle;
  final bool isRepeat;
  final double volume;

  const PlaybackState({
    this.currentTrack,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.currentIndex = -1,
    this.isShuffle = false,
    this.isRepeat = false,
    this.volume = 1.0,
  });

  PlaybackState copyWith({
    DownloadTask? Function()? currentTrack,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    List<DownloadTask>? queue,
    int? currentIndex,
    bool? isShuffle,
    bool? isRepeat,
    double? volume,
  }) {
    return PlaybackState(
      currentTrack: currentTrack != null ? currentTrack() : this.currentTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      isRepeat: isRepeat ?? this.isRepeat,
      volume: volume ?? this.volume,
    );
  }
}

class AudioPlayerNotifier extends Notifier<PlaybackState> {
  late final AudioPlayer _player;
  List<int> _shuffledIndices = [];

  @override
  PlaybackState build() {
    _player = AudioPlayer();

    // Listen to players events
    _player.onPositionChanged.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _player.onDurationChanged.listen((dur) {
      state = state.copyWith(duration: dur);
    });

    _player.onPlayerStateChanged.listen((playerState) {
      state = state.copyWith(isPlaying: playerState == PlayerState.playing);
    });

    _player.onPlayerComplete.listen((event) {
      _handlePlaybackComplete();
    });

    ref.onDispose(() {
      _player.dispose();
    });

    return const PlaybackState();
  }

  Future<void> playTrack(
    DownloadTask track,
    List<DownloadTask> newQueue,
  ) async {
    final idx = newQueue.indexWhere((t) => t.id == track.id);

    state = state.copyWith(
      currentTrack: () => track,
      queue: newQueue,
      currentIndex: idx >= 0 ? idx : 0,
      position: Duration.zero,
      duration: Duration.zero,
    );

    if (state.isShuffle) {
      _generateShuffledIndices(newQueue.length, state.currentIndex);
    }

    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    final track = state.currentTrack;
    if (track == null || track.savePath == null) return;

    try {
      await _player.stop();
      await _player.setSourceDeviceFile(track.savePath!);
      await _player.resume();
    } catch (e) {
      debugPrint('Error playing track: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    state = state.copyWith(
      currentTrack: () => null,
      isPlaying: false,
      position: Duration.zero,
      duration: Duration.zero,
    );
  }

  Future<void> togglePlay() async {
    if (state.currentTrack == null) return;
    if (state.isPlaying) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.resume();
  }

  Future<void> seek(Duration pos) async {
    await _player.seek(pos);
  }

  Future<void> setVolume(double vol) async {
    final volume = vol.clamp(0.0, 1.0);
    state = state.copyWith(volume: volume);
    await _player.setVolume(volume);
  }

  void toggleShuffle() {
    final shuffle = !state.isShuffle;
    state = state.copyWith(isShuffle: shuffle);
    if (shuffle && state.queue.isNotEmpty) {
      _generateShuffledIndices(state.queue.length, state.currentIndex);
    }
  }

  void toggleRepeat() {
    state = state.copyWith(isRepeat: !state.isRepeat);
  }

  Future<void> next() async {
    if (state.queue.isEmpty) return;

    if (state.isRepeat) {
      await seek(Duration.zero);
      await resume();
      return;
    }

    int nextIdx = _getNextIndex();
    if (nextIdx != -1) {
      state = state.copyWith(
        currentIndex: nextIdx,
        currentTrack: () => state.queue[nextIdx],
        position: Duration.zero,
        duration: Duration.zero,
      );
      await _playCurrent();
    } else {
      // Stopped at end of queue
      await _player.stop();
      state = state.copyWith(currentTrack: () => null, isPlaying: false);
    }
  }

  Future<void> previous() async {
    if (state.queue.isEmpty) return;

    // Restart song if played more than 3 seconds
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prevIdx = _getPreviousIndex();
    if (prevIdx != -1) {
      state = state.copyWith(
        currentIndex: prevIdx,
        currentTrack: () => state.queue[prevIdx],
        position: Duration.zero,
        duration: Duration.zero,
      );
      await _playCurrent();
    }
  }

  int _getNextIndex() {
    if (state.queue.isEmpty) return -1;

    if (state.isShuffle && _shuffledIndices.isNotEmpty) {
      final currentShuffledIdx = _shuffledIndices.indexOf(state.currentIndex);
      if (currentShuffledIdx != -1 &&
          currentShuffledIdx < _shuffledIndices.length - 1) {
        return _shuffledIndices[currentShuffledIdx + 1];
      }
      return -1; // End of shuffled list
    } else {
      if (state.currentIndex < state.queue.length - 1) {
        return state.currentIndex + 1;
      }
      return -1; // End of sequential list
    }
  }

  int _getPreviousIndex() {
    if (state.queue.isEmpty) return -1;

    if (state.isShuffle && _shuffledIndices.isNotEmpty) {
      final currentShuffledIdx = _shuffledIndices.indexOf(state.currentIndex);
      if (currentShuffledIdx > 0) {
        return _shuffledIndices[currentShuffledIdx - 1];
      }
      return -1;
    } else {
      if (state.currentIndex > 0) {
        return state.currentIndex - 1;
      }
      return -1;
    }
  }

  void _handlePlaybackComplete() {
    next();
  }

  void _generateShuffledIndices(int length, int currentIndex) {
    _shuffledIndices = List<int>.generate(length, (i) => i);
    // Keep current index as the first element of shuffled list
    _shuffledIndices.remove(currentIndex);
    _shuffledIndices.shuffle(Random());
    _shuffledIndices.insert(0, currentIndex);
  }
}

final audioPlayerProvider =
    NotifierProvider<AudioPlayerNotifier, PlaybackState>(() {
      return AudioPlayerNotifier();
    });
