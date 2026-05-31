import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/player/player_service.dart';
import 'glassmorphic_container.dart';

class FullPlayer extends ConsumerWidget {
  const FullPlayer({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getQualityLabel(String qualityId) {
    switch (qualityId) {
      case '5':
        return 'MP3 • 320 kbps';
      case '6':
        return 'FLAC • 16-Bit / 44.1 kHz';
      case '7':
        return 'Hi-Res • 24-Bit / 96 kHz';
      case '27':
        return 'Hi-Res • 24-Bit / 192 kHz';
      default:
        return 'Lossless FLAC';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioPlayerProvider);
    final notifier = ref.read(audioPlayerProvider.notifier);
    
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final track = state.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final totalMs = state.duration.inMilliseconds;
    final currentMs = state.position.inMilliseconds;
    final progressVal = totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;

    return GlassmorphicContainer(
      borderRadius: 28,
      blur: 35, // Deep ambient frosted blur
      color: isDark 
          ? const Color(0xFF121212).withAlpha(140) 
          : cs.surface.withAlpha(180),
      borderColor: cs.outlineVariant.withAlpha(45),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Blurred Ambient Color Backdrop ──
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.15 : 0.08,
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      cs.primary,
                      cs.secondary,
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Main Content Area ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  // Drag Handle & Header Close
                  const SizedBox(height: 8),
                  Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Now Playing',
                        style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                      IconButton(
                        icon: const Icon(Icons.queue_music_rounded, size: 22),
                        onPressed: () {
                          // Playback Queue alert / view could be added in a future enhancement
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Queue contains ${state.queue.length} track(s)'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // ── Immersive Cover Art Glow Card ──
                  Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withAlpha(60),
                            blurRadius: 36,
                            offset: const Offset(0, 14),
                          )
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: track.coverUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: track.coverUrl,
                                fit: BoxFit.cover,
                                placeholder: (_, _a) => Container(color: cs.surfaceContainerHighest),
                                errorWidget: (_, _a, _b) => Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(Icons.music_note, size: 80, color: cs.onSurfaceVariant),
                                ),
                              )
                            : Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(Icons.music_note, size: 80, color: cs.onSurfaceVariant),
                              ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Title & Artist details ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        track.trackTitle,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        track.artistName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      
                      // ── High Quality Audio Badge ──
                      GlassmorphicContainer(
                        borderRadius: 20,
                        blur: 10,
                        color: track.quality != '5' 
                            ? cs.tertiaryContainer.withAlpha(100) 
                            : cs.secondaryContainer.withAlpha(100),
                        borderColor: cs.outlineVariant.withAlpha(50),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              track.quality != '5' ? Icons.high_quality_rounded : Icons.audiotrack_rounded,
                              size: 16,
                              color: track.quality != '5' ? cs.onTertiaryContainer : cs.onSecondaryContainer,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getQualityLabel(track.quality),
                              style: tt.labelMedium?.copyWith(
                                color: track.quality != '5' ? cs.onTertiaryContainer : cs.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // ── Seek Bar & Position sliders ──
                  Column(
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
                          value: progressVal,
                          onChanged: (val) {
                            final targetMs = (val * totalMs).toInt();
                            notifier.seek(Duration(milliseconds: targetMs));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(state.position),
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatDuration(state.duration),
                              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // ── Media Playback Keys ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle button
                      IconButton(
                        icon: Icon(
                          Icons.shuffle_rounded,
                          color: state.isShuffle ? cs.primary : cs.onSurfaceVariant.withAlpha(140),
                        ),
                        onPressed: notifier.toggleShuffle,
                      ),
                      
                      // Previous button
                      IconButton(
                        icon: Icon(Icons.skip_previous_rounded, size: 36, color: cs.onSurface),
                        onPressed: notifier.previous,
                      ),
                      
                      // Play/Pause circle button
                      Container(
                        height: 72, width: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary,
                        ),
                        child: IconButton(
                          icon: Icon(
                            state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 40,
                            color: cs.onPrimary,
                          ),
                          onPressed: notifier.togglePlay,
                        ),
                      ),
                      
                      // Next button
                      IconButton(
                        icon: Icon(Icons.skip_next_rounded, size: 36, color: cs.onSurface),
                        onPressed: notifier.next,
                      ),
                      
                      // Repeat button
                      IconButton(
                        icon: Icon(
                          Icons.repeat_rounded,
                          color: state.isRepeat ? cs.primary : cs.onSurfaceVariant.withAlpha(140),
                        ),
                        onPressed: notifier.toggleRepeat,
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // ── Volume Slider Controls ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.volume_down_rounded, size: 20, color: cs.onSurfaceVariant),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                              activeTrackColor: cs.onSurfaceVariant,
                              inactiveTrackColor: cs.outlineVariant.withAlpha(60),
                              thumbColor: cs.onSurfaceVariant,
                            ),
                            child: Slider(
                              value: state.volume,
                              onChanged: notifier.setVolume,
                            ),
                          ),
                        ),
                        Icon(Icons.volume_up_rounded, size: 20, color: cs.onSurfaceVariant),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
