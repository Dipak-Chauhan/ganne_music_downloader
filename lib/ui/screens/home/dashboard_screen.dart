import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/local/database.dart';
import '../../../data/providers/service_providers.dart';
import '../../../services/player/player_service.dart';
import '../../../core/utils/app_toast.dart';
import '../../widgets/glassmorphic_container.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Function(int) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double _ganneFolderSizeMB = 0.0;
  bool _calculatingSize = false;
  int? _lastCompletedCount;
  late final Stream<List<DownloadTask>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = ref.read(databaseProvider).watchAllTasks();
    _updateFolderSize();
  }

  Future<void> _updateFolderSize() async {
    if (_calculatingSize) return;
    _calculatingSize = true;

    try {
      final downloadPath = ref.read(downloadServiceProvider).baseMusicDir;
      // Offload file system I/O to an isolate so it doesn't block the UI thread
      final size = await compute(_calculateSizeIsolate, downloadPath);
      if (mounted) {
        setState(() {
          _ganneFolderSizeMB = size;
          _calculatingSize = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _calculatingSize = false);
    }
  }

  /// Static top-level function for compute() — runs in a separate isolate
  static double _calculateSizeIsolate(String dirPath) {
    try {
      final dir = Directory(dirPath);
      if (!dir.existsSync()) return 0.0;
      int bytes = 0;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          bytes += entity.lengthSync();
        }
      }
      return bytes / (1024 * 1024);
    } catch (_) {
      return 0.0;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 21 || hour < 5) return 'Late night vibes';
    if (hour < 12) return 'Morning beats';
    if (hour < 17) return 'Midday soundtrack';
    return 'Sunset vibes';
  }

  String _formatSize(double mb) {
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(2)} GB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: StreamBuilder<List<DownloadTask>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          final tasks = snapshot.data ?? [];
          final completedTasks = tasks
              .where((t) => t.status == 'completed' || t.status == 'library')
              .toList();
          final pendingTasks = tasks
              .where((t) => t.status == 'pending')
              .toList();
          final activeTasks = tasks
              .where((t) => t.status == 'downloading')
              .toList();
          final failedTasks = tasks.where((t) => t.status == 'failed').toList();

          // Sort completed tasks by added date to show most recent first
          final recentCompleted = List<DownloadTask>.from(completedTasks)
            ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

          // Proactively recalculate folder size if a new download finishes or a task is deleted
          if (_lastCompletedCount == null ||
              _lastCompletedCount != completedTasks.length) {
            _lastCompletedCount = completedTasks.length;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _updateFolderSize(),
            );
          }

          return RefreshIndicator(
            onRefresh: _updateFolderSize,
            color: cs.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  collapsedHeight: 70,
                  pinned: true,
                  backgroundColor: cs.surface,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 12),
                    centerTitle: false,
                    title: Text(
                      '${_getGreeting()},',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back to Ganne. Here is your music status.',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),

                        _buildStatsCard(
                          cs,
                          tt,
                          completedTasks.length,
                          activeTasks.length + pendingTasks.length,
                          failedTasks.length,
                        ),
                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Downloads',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (completedTasks.length > 5)
                              TextButton(
                                onPressed: () =>
                                    widget.onNavigate(2), // Navigate to Library
                                child: const Text('View All'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRecentCarousel(
                          recentCompleted.take(5).toList(),
                          completedTasks,
                          cs,
                          tt,
                        ),

                        const SizedBox(height: 32),

                        Text(
                          'Quick Actions',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActionsGrid(
                          cs,
                          tt,
                          activeTasks.length + pendingTasks.length,
                        ),

                        const SizedBox(height: 160),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(
    ColorScheme cs,
    TextTheme tt,
    int completedCount,
    int activeQueueCount,
    int failedCount,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassmorphicContainer(
      borderRadius: 24,
      blur: 0,
      color: isDark
          ? cs.primaryContainer.withAlpha(45)
          : cs.primaryContainer.withAlpha(80),
      borderColor: cs.primary.withAlpha(65),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Stack(
        children: [
          // Subtle glow shapes
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.tertiaryContainer.withAlpha(90),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Library Storage Size',
                          style: tt.labelLarge?.copyWith(
                            color: cs.onPrimaryContainer.withAlpha(180),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (_calculatingSize)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black26,
                                ),
                              )
                            else
                              Text(
                                _formatSize(_ganneFolderSizeMB),
                                style: tt.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: cs.onPrimaryContainer,
                                  letterSpacing: -1,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface.withAlpha(180),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: cs.primary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat('Tracks', completedCount.toString(), cs, tt),
                    Container(
                      width: 1,
                      height: 28,
                      color: cs.outlineVariant.withAlpha(100),
                    ),
                    _buildMiniStat(
                      'In Queue',
                      activeQueueCount.toString(),
                      cs,
                      tt,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: cs.outlineVariant.withAlpha(100),
                    ),
                    _buildMiniStat(
                      'Failed',
                      failedCount.toString(),
                      cs,
                      tt,
                      isError: failedCount > 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    ColorScheme cs,
    TextTheme tt, {
    bool isError = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: isError ? cs.error : cs.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: cs.onPrimaryContainer.withAlpha(160),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCarousel(
    List<DownloadTask> recent,
    List<DownloadTask> allCompleted,
    ColorScheme cs,
    TextTheme tt,
  ) {
    if (recent.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cs.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.library_music_outlined, size: 40, color: cs.outline),
                const SizedBox(height: 12),
                Text(
                  'No downloads completed yet.',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your downloaded tracks will appear here.',
                  style: tt.bodySmall?.copyWith(color: cs.outline),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = recent.length * 152.0 - 12.0;
        final fits = constraints.maxWidth >= totalWidth;
        return SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: fits
                ? const NeverScrollableScrollPhysics()
                : null,
            clipBehavior: Clip.none,
            itemCount: recent.length,
            itemBuilder: (context, index) {
              final task = recent[index];
              return Container(
                width: 140,
                margin: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
                child: GlassmorphicContainer(
                  borderRadius: 16,
                  blur: 0,
                  padding: EdgeInsets.zero,
                  margin: EdgeInsets.zero,
                  color: Colors.black.withAlpha(30),
                  child: InkWell(
                    onTap: () {
                      // Navigate to Library/details sheet or play in-app
                      ref
                          .read(audioPlayerProvider.notifier)
                          .playTrack(task, allCompleted);
                      AppToast.success(context, 'Playing "${task.trackTitle}"');
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Cover Art Image
                        task.coverUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: task.coverUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: 280, // Optimized cache size
                                memCacheHeight: 280,
                                placeholder: (_, a) =>
                                    Container(color: cs.surfaceContainerHighest),
                                errorWidget: (_, a, b) => Container(
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(
                                    Icons.music_note,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Container(
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                        // Bottom gradient overlay
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withAlpha(220),
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  task.trackTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  task.artistName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tt.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Quick Play Floating Circle Tonal Button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primaryContainer.withAlpha(220),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: cs.onPrimaryContainer,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuickActionsGrid(ColorScheme cs, TextTheme tt, int queueCount) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildActionCard(
          title: 'Search Music',
          subtitle: 'Find albums & tracks',
          icon: Icons.search_rounded,
          color: cs.primaryContainer,
          onTap: () => widget.onNavigate(1), // Nav to Search
        ),
        _buildActionCard(
          title: 'Active Queue',
          subtitle: queueCount > 0 ? '$queueCount active item(s)' : 'Idle',
          icon: Icons.downloading_rounded,
          color: cs.secondaryContainer,
          onTap: () => widget.onNavigate(2), // Nav to Queue/Library indexes
          badge: queueCount > 0 ? queueCount.toString() : null,
        ),
        _buildActionCard(
          title: 'My Library',
          subtitle: 'Play downloaded songs',
          icon: Icons.library_music_rounded,
          color: cs.tertiaryContainer,
          onTap: () => widget.onNavigate(3), // Nav to Library
        ),
        _buildActionCard(
          title: 'Settings',
          subtitle: 'Configure output / themes',
          icon: Icons.settings_rounded,
          color: cs.surfaceContainerHigh,
          onTap: () => widget.onNavigate(4), // Nav to Settings
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassmorphicContainer(
      borderRadius: 20,
      blur: 0,
      color: color.withAlpha(isDark ? 40 : 80),
      borderColor: cs.outlineVariant.withAlpha(60),
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: cs.onSurface, size: 28),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
