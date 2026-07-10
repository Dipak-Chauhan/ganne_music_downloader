import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/player/player_service.dart';
import 'full_player.dart';
import 'glassmorphic_container.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final track = ref.watch(audioPlayerProvider.select((s) => s.currentTrack));
    final isPlaying = ref.watch(audioPlayerProvider.select((s) => s.isPlaying));
    final notifier = ref.read(audioPlayerProvider.notifier);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (track == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Dismissible(
        key: Key('mini_player_${track.trackId}'),
        direction: DismissDirection.down,
        onDismissed: (_) {
          notifier.stop();
        },
        child: GlassmorphicContainer(
          borderRadius: 18,
          blur: 20,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                showDragHandle: false,
                backgroundColor: Colors.transparent,
                builder: (_) => const FullPlayer(),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Micro Progress Bar at the top of the card (Isolated from main card rebuilds)
                const _MiniProgressBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Spinning / Rounded album art
                      Hero(
                        tag: 'player_album_art',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: track.coverUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: track.coverUrl,
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 84, // Optimized cache size
                                  memCacheHeight: 84,
                                  placeholder: (_, a) => Container(
                                    width: 42,
                                    height: 42,
                                    color: cs.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.music_note,
                                      size: 18,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 42,
                                  height: 42,
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.music_note,
                                    size: 18,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Text details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              track.trackTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              track.artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: tt.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Play/Pause button
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 28,
                          color: cs.primary,
                        ),
                        onPressed: notifier.togglePlay,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),

                      // Next button
                      IconButton(
                        icon: Icon(
                          Icons.skip_next_rounded,
                          size: 26,
                          color: cs.onSurfaceVariant,
                        ),
                        onPressed: notifier.next,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// High-performance progress bar sub-widget
class _MiniProgressBar extends ConsumerWidget {
  const _MiniProgressBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(audioPlayerProvider.select((s) => s.position));
    final duration = ref.watch(audioPlayerProvider.select((s) => s.duration));
    final cs = Theme.of(context).colorScheme;

    final progressVal = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return LinearProgressIndicator(
      value: progressVal.clamp(0.0, 1.0),
      minHeight: 2.5,
      color: cs.primary,
      backgroundColor: cs.outlineVariant.withAlpha(50),
    );
  }
}
