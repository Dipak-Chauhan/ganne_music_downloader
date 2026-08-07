import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/player/player_service.dart';
import '../../data/local/database.dart';
import 'glassmorphic_container.dart';

class FullPlayer extends ConsumerStatefulWidget {
  const FullPlayer({super.key});

  @override
  ConsumerState<FullPlayer> createState() => _FullPlayerState();
}

class _FullPlayerState extends ConsumerState<FullPlayer> {
  bool _showQueue = false;

  String _getQualityLabel(String qualityId) {
    switch (qualityId) {
      case '5':
        return 'MP3 320 kbps';
      case '6':
        return 'FLAC 16-bit / 44.1 kHz';
      case '7':
        return 'FLAC 24-bit / 96 kHz';
      case '27':
        return 'FLAC 24-bit / 192 kHz';
      default:
        return 'Lossless FLAC';
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = ref.watch(audioPlayerProvider.select((s) => s.currentTrack));
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final isShuffle = ref.watch(audioPlayerProvider.select((s) => s.isShuffle));
    final isRepeat = ref.watch(audioPlayerProvider.select((s) => s.isRepeat));
    final queue = ref.watch(audioPlayerProvider.select((s) => s.queue));
    final volume = ref.watch(audioPlayerProvider.select((s) => s.volume));
    final notifier = ref.read(audioPlayerProvider.notifier);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (track == null) return const SizedBox.shrink();

    return GlassmorphicContainer(
      borderRadius: 28,
      blur: 0,
      color: isDark ? cs.surface : cs.surface,
      borderColor: cs.outlineVariant.withAlpha(30),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      boxShadow: const [],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: track.coverUrl.isNotEmpty
                    ? Opacity(
                        key: ValueKey('backdrop_${track.trackId}'),
                        opacity: isDark ? 0.15 : 0.08,
                        child: CachedNetworkImage(
                          imageUrl: track.coverUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 64,
                          memCacheHeight: 64,
                        ),
                      )
                    : Container(
                        key: const ValueKey('backdrop_fallback'),
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment.topCenter,
                            radius: 1.2,
                            colors: [
                              cs.primary.withAlpha(isDark ? 30 : 15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          // Subtle contrast adjustment overlay
          Positioned.fill(
            child: Container(
              color: isDark
                  ? Colors.black.withAlpha(60)
                  : Colors.white.withAlpha(30),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, playerConstraints) {
                final isCompact = playerConstraints.maxHeight < 680;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 16 : 24,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: isCompact ? 6 : 12),
                          Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.onSurfaceVariant.withAlpha(90),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          SizedBox(height: isCompact ? 4 : 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                tooltip: 'Minimize player',
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 28,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              Text(
                                _showQueue ? 'Queue' : 'Now Playing',
                                style: tt.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              IconButton(
                                tooltip: _showQueue
                                    ? 'Show now playing'
                                    : 'Show queue',
                                icon: Icon(
                                  Icons.queue_music_rounded,
                                  size: 22,
                                  color: _showQueue ? cs.primary : cs.onSurface,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: _showQueue
                                      ? cs.primaryContainer.withAlpha(150)
                                      : Colors.transparent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showQueue = !_showQueue;
                                  });
                                },
                              ),
                            ],
                          ),

                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position:
                                            Tween<Offset>(
                                              begin: const Offset(0.0, 0.04),
                                              end: Offset.zero,
                                            ).animate(
                                              CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeOutCubic,
                                              ),
                                            ),
                                        child: child,
                                      ),
                                    );
                                  },
                              child: _showQueue
                                  ? _buildQueueView(
                                      context,
                                      queue,
                                      track,
                                      isShuffle,
                                      cs,
                                      tt,
                                    )
                                  : _buildPlayerView(context, track, cs, tt),
                            ),
                          ),

                          SizedBox(height: isCompact ? 8 : 16),

                          if (!_showQueue)
                            const _FullPlayerSeekBar()
                          else
                            const SizedBox(
                              height: 32,
                            ), // Layout placeholder to maintain height consistency

                          SizedBox(height: isCompact ? 8 : 16),

                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Shuffle button with glowing indicator dot
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: isShuffle
                                            ? 'Disable shuffle'
                                            : 'Enable shuffle',
                                        icon: Icon(
                                          Icons.shuffle_rounded,
                                          color: isShuffle
                                              ? cs.primary
                                              : cs.onSurfaceVariant.withAlpha(
                                                  190,
                                                ),
                                        ),
                                        onPressed: notifier.toggleShuffle,
                                        style: IconButton.styleFrom(
                                          minimumSize: const Size(44, 44),
                                          backgroundColor: isShuffle
                                              ? cs.primaryContainer.withAlpha(
                                                  130,
                                                )
                                              : Colors.transparent,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isShuffle
                                              ? cs.primary
                                              : Colors.transparent,
                                          boxShadow: isShuffle
                                              ? [
                                                  BoxShadow(
                                                    color: cs.primary.withAlpha(
                                                      180,
                                                    ),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Previous button
                                  IconButton(
                                    tooltip: 'Previous track',
                                    icon: Icon(
                                      Icons.skip_previous_rounded,
                                      size: isCompact ? 32 : 36,
                                      color: cs.onSurface,
                                    ),
                                    onPressed: notifier.previous,
                                  ),

                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: cs.primary.withAlpha(120),
                                          blurRadius: isCompact ? 14 : 20,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: IconButton.filled(
                                      key: const ValueKey(
                                        'full_player_play_pause',
                                      ),
                                      tooltip: isPlaying ? 'Pause' : 'Play',
                                      onPressed: notifier.togglePlay,
                                      style: IconButton.styleFrom(
                                        fixedSize: Size.square(
                                          isCompact ? 62 : 72,
                                        ),
                                        backgroundColor: cs.primary,
                                        foregroundColor: cs.onPrimary,
                                        side: BorderSide(
                                          color: Colors.white.withAlpha(80),
                                          width: 1.5,
                                        ),
                                      ),
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: isCompact ? 36 : 40,
                                      ),
                                    ),
                                  ),

                                  // Next button
                                  IconButton(
                                    tooltip: 'Next track',
                                    icon: Icon(
                                      Icons.skip_next_rounded,
                                      size: isCompact ? 32 : 36,
                                      color: cs.onSurface,
                                    ),
                                    onPressed: notifier.next,
                                  ),

                                  // Repeat button with glowing indicator dot
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: isRepeat
                                            ? 'Disable repeat'
                                            : 'Enable repeat',
                                        icon: Icon(
                                          isRepeat
                                              ? Icons.repeat_one_rounded
                                              : Icons.repeat_rounded,
                                          color: isRepeat
                                              ? cs.primary
                                              : cs.onSurfaceVariant.withAlpha(
                                                  190,
                                                ),
                                        ),
                                        onPressed: notifier.toggleRepeat,
                                        style: IconButton.styleFrom(
                                          minimumSize: const Size(44, 44),
                                          backgroundColor: isRepeat
                                              ? cs.primaryContainer.withAlpha(
                                                  130,
                                                )
                                              : Colors.transparent,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 250,
                                        ),
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isRepeat
                                              ? cs.primary
                                              : Colors.transparent,
                                          boxShadow: isRepeat
                                              ? [
                                                  BoxShadow(
                                                    color: cs.primary.withAlpha(
                                                      180,
                                                    ),
                                                    blurRadius: 6,
                                                    spreadRadius: 1,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: isCompact ? 8 : 14),

                          if (!isCompact)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.volume_down_rounded,
                                    size: 20,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 3,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 5,
                                        ),
                                        activeTrackColor: cs.onSurfaceVariant,
                                        inactiveTrackColor: cs.outlineVariant
                                            .withAlpha(60),
                                        thumbColor: cs.onSurfaceVariant,
                                      ),
                                      child: Slider(
                                        key: const ValueKey(
                                          'full_player_volume',
                                        ),
                                        value: volume,
                                        onChanged: notifier.setVolume,
                                        semanticFormatterCallback: (value) =>
                                            '${(value * 100).round()} percent',
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.volume_up_rounded,
                                    size: 20,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),

                          SizedBox(height: isCompact ? 10 : 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Main Player Cover Art & Track details
  Widget _buildPlayerView(
    BuildContext context,
    DownloadTask track,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout =
            constraints.maxWidth >= 600 &&
            constraints.maxWidth > constraints.maxHeight * 1.25;
        if (useWideLayout) {
          return _buildWidePlayerView(context, constraints, track, cs, tt);
        }

        final artworkSize = (constraints.maxHeight * 0.55).clamp(120.0, 300.0);
        return SingleChildScrollView(
          key: const ValueKey('full_player_portrait_layout'),
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                Center(
                  child: Hero(
                    tag: 'player_album_art',
                    child: Container(
                      width: artworkSize,
                      height: artworkSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          // Soft elegant black ambient drop-shadow
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 140 : 80),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                          // Soft vibrant primary colored glow shadow
                          BoxShadow(
                            color: cs.primary.withAlpha(80),
                            blurRadius: 32,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withAlpha(isDark ? 40 : 80),
                          width: 1.2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: track.coverUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.coverUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 520,
                                memCacheHeight: 520,
                                placeholder: (context, url) => Container(
                                  color: cs.surfaceContainerHighest,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.music_note,
                                    size: 70,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note,
                                  size: 70,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.trackTitle,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artistName,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (track.albumTitle.isNotEmpty &&
                        track.albumTitle != track.trackTitle) ...[
                      const SizedBox(height: 2),
                      Text(
                        track.albumTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant.withAlpha(180),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    _buildQualityChip(track, cs, tt),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWidePlayerView(
    BuildContext context,
    BoxConstraints constraints,
    DownloadTask track,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final artworkSize = math
        .min(constraints.maxWidth * 0.42, constraints.maxHeight - 20)
        .clamp(104.0, 280.0)
        .toDouble();
    final albumDetails = <String>[
      if (track.albumTitle.isNotEmpty && track.albumTitle != track.trackTitle)
        track.albumTitle,
      if (track.year != null) track.year.toString(),
    ].join(' • ');

    return Row(
      key: const ValueKey('full_player_wide_layout'),
      children: [
        Expanded(
          child: Center(
            child: Hero(
              tag: 'player_album_art',
              child: Container(
                width: artworkSize,
                height: artworkSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withAlpha(isDark ? 40 : 80),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 130 : 70),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: cs.primary.withAlpha(60),
                      blurRadius: 28,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildArtworkImage(track, cs, 520),
              ),
            ),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.trackTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  track.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (albumDetails.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    albumDetails,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withAlpha(190),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildQualityChip(track, cs, tt),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtworkImage(DownloadTask track, ColorScheme cs, int cacheSize) {
    if (track.coverUrl.isEmpty) {
      return ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.music_note_rounded,
          size: 64,
          color: cs.onSurfaceVariant,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: track.coverUrl,
      fit: BoxFit.cover,
      memCacheWidth: cacheSize,
      memCacheHeight: cacheSize,
      placeholder: (_, _) => ColoredBox(color: cs.surfaceContainerHighest),
      errorWidget: (_, _, _) => ColoredBox(
        color: cs.surfaceContainerHighest,
        child: Icon(
          Icons.music_note_rounded,
          size: 64,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildQualityChip(DownloadTask track, ColorScheme cs, TextTheme tt) {
    final isHiRes = track.quality != '5';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isHiRes
            ? cs.tertiaryContainer.withAlpha(70)
            : cs.secondaryContainer.withAlpha(70),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isHiRes ? cs.tertiary : cs.secondary).withAlpha(110),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHiRes ? Icons.high_quality_rounded : Icons.audiotrack_rounded,
            size: 15,
            color: isHiRes ? cs.onTertiaryContainer : cs.onSecondaryContainer,
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              _getQualityLabel(track.quality),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelSmall?.copyWith(
                color: isHiRes
                    ? cs.onTertiaryContainer
                    : cs.onSecondaryContainer,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Scrolling Playback Queue View
  Widget _buildQueueView(
    BuildContext context,
    List<DownloadTask> queue,
    DownloadTask currentTrack,
    bool isShuffle,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (queue.isEmpty) {
      return Center(
        key: const ValueKey('queue_empty'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music_rounded, size: 48, color: cs.outlineVariant),
            const SizedBox(height: 12),
            Text(
              'Queue is empty',
              style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final currentIndex = queue.indexWhere(
      (queuedTrack) => queuedTrack.id == currentTrack.id,
    );
    final isAtQueueEnd =
        queue.length == 1 || (!isShuffle && currentIndex == queue.length - 1);

    return Column(
      key: const ValueKey('queue_list_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PLAYBACK QUEUE',
                style: tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: cs.primary,
                ),
              ),
              Text(
                '${queue.length} ${queue.length == 1 ? 'track' : 'tracks'}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: queue.length + (isAtQueueEnd ? 1 : 0),
            padding: const EdgeInsets.only(bottom: 24),
            itemBuilder: (context, index) {
              if (index == queue.length) {
                return Padding(
                  key: const ValueKey('queue_end_state'),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'End of queue',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final qTrack = queue[index];
              final isCurrent = qTrack.id == currentTrack.id;

              return Card(
                color: isCurrent
                    ? cs.primaryContainer.withAlpha(90)
                    : cs.surfaceContainerLow.withAlpha(60),
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 2,
                  ),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: qTrack.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: qTrack.coverUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            memCacheWidth: 80,
                            memCacheHeight: 80,
                            placeholder: (context, url) => Container(
                              width: 40,
                              height: 40,
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note,
                                size: 18,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            color: cs.surfaceContainerHighest,
                            child: Icon(
                              Icons.music_note,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                  ),
                  title: Text(
                    qTrack.trackTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodyMedium?.copyWith(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: isCurrent ? cs.onPrimaryContainer : cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    qTrack.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(
                      color: isCurrent
                          ? cs.onPrimaryContainer.withAlpha(180)
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  trailing: isCurrent
                      ? Icon(
                          Icons.volume_up_rounded,
                          color: cs.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    ref
                        .read(audioPlayerProvider.notifier)
                        .playTrack(qTrack, queue);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FullPlayerSeekBar extends ConsumerStatefulWidget {
  const _FullPlayerSeekBar();

  @override
  ConsumerState<_FullPlayerSeekBar> createState() => _FullPlayerSeekBarState();
}

class _FullPlayerSeekBarState extends ConsumerState<_FullPlayerSeekBar> {
  double? _dragValue;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration = ref.watch(audioPlayerProvider.select((s) => s.duration));
    final notifier = ref.read(audioPlayerProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final totalMs = duration.inMilliseconds;
    final currentMs = position.inMilliseconds;
    final playbackProgress = totalMs > 0
        ? (currentMs / totalMs).clamp(0.0, 1.0)
        : 0.0;
    final progress = _dragValue ?? playbackProgress;
    final displayedPosition = _dragValue == null
        ? position
        : Duration(milliseconds: (progress * totalMs).round());

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: cs.primary,
            inactiveTrackColor: cs.outlineVariant.withAlpha(80),
            thumbColor: cs.primary,
          ),
          child: Slider(
            key: const ValueKey('full_player_seek'),
            value: progress,
            onChanged: totalMs > 0
                ? (value) => setState(() => _dragValue = value)
                : null,
            onChangeEnd: totalMs > 0
                ? (value) {
                    setState(() => _dragValue = null);
                    notifier.seek(
                      Duration(milliseconds: (value * totalMs).round()),
                    );
                  }
                : null,
            semanticFormatterCallback: (value) => _formatDuration(
              Duration(milliseconds: (value * totalMs).round()),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(displayedPosition),
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDuration(duration),
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
