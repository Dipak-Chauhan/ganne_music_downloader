import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/local/database.dart';
import '../../../data/providers/service_providers.dart';
import '../../../services/download/download_service.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ActiveDownloadInfo? _zipInfo;
  StreamSubscription? _zipSub;
  late final Stream<List<DownloadTask>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = ref.read(databaseProvider).watchAllTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(downloadServiceProvider);
      // Seed initial value
      final current = service.activeDownload;
      if (current != null && current.trackTitle.startsWith('Zipping:')) {
        setState(() => _zipInfo = current);
      }
      // Listen reactively
      _zipSub = service.activeDownloadStream.listen((info) {
        if (!mounted) return;
        if (info != null && info.trackTitle.startsWith('Zipping:')) {
          setState(() => _zipInfo = info);
        } else {
          if (_zipInfo != null) setState(() => _zipInfo = null);
        }
      });
    });
  }

  @override
  void dispose() {
    _zipSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final db = ref.watch(databaseProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Download Queue'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_failed') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    icon: Icon(Icons.delete_sweep, color: cs.error),
                    title: const Text('Clear Failed'),
                    content: const Text('Remove all failed downloads?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () {
                          db.clearFailed();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear Failed'),
                      ),
                    ],
                  ),
                );
              } else if (value == 'clear_completed') {
                db.archiveCompleted();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear_failed',
                child: Text('Clear all failed'),
              ),
              PopupMenuItem(
                value: 'clear_completed',
                child: Text('Clear all completed'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<DownloadTask>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: cs.error),
                  const SizedBox(height: 12),
                  Text(
                    'Error: ${snapshot.error}',
                    style: tt.bodyMedium?.copyWith(color: cs.error),
                  ),
                ],
              ),
            );
          }

          final dbTasks = (snapshot.data ?? [])
              .where((task) => task.status != 'library')
              .toList();

          // Build combined list: zip task at top + db tasks
          final List<Widget> items = [];

          // ZIP download card (reactive from stream)
          if (_zipInfo != null) {
            items.add(_ZipProgressCard(info: _zipInfo!));
          }

          // DB tasks
          for (final task in dbTasks) {
            items.add(
              _QueueItemCard(key: ValueKey(task.id), task: task, db: db),
            );
          }

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 64,
                    color: cs.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active downloads',
                    style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Search and queue music to start',
                    style: tt.bodyMedium?.copyWith(color: cs.outlineVariant),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 160),
            children: items,
          );
        },
      ),
    );
  }
}

/// Dedicated card for active ZIP download progress
class _ZipProgressCard extends StatelessWidget {
  final ActiveDownloadInfo info;
  const _ZipProgressCard({required this.info});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = info.progress.clamp(0.0, 1.0);
    final percent = (progress * 100).toInt();
    final isComplete = progress >= 1.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: cs.surfaceContainerHigh,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ZIP icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.folder_zip,
                    color: cs.onPrimaryContainer,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.archive_outlined,
                            size: 14,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ZIP Archive',
                            style: tt.labelSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.albumTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info.artistName,
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
                if (isComplete)
                  Icon(Icons.check_circle_rounded, color: cs.tertiary, size: 28)
                else
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 3,
                          backgroundColor: cs.surfaceContainerHighest,
                        ),
                      ),
                      Text(
                        '$percent',
                        style: tt.labelSmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          // Progress bar at bottom
          if (!isComplete)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(12),
              ),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 4,
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHighest,
              ),
            ),
        ],
      ),
    );
  }
}

class _QueueItemCard extends ConsumerStatefulWidget {
  final DownloadTask task;
  final AppDatabase db;

  const _QueueItemCard({super.key, required this.task, required this.db});

  @override
  ConsumerState<_QueueItemCard> createState() => _QueueItemCardState();
}

class _QueueItemCardState extends ConsumerState<_QueueItemCard> {
  double? liveProgress;
  StreamSubscription? _progressSub;

  @override
  void initState() {
    super.initState();
    final service = ref.read(downloadServiceProvider);
    liveProgress = service.currentProgress[widget.task.trackId];
    _progressSub = service.progressStream.listen((progressMap) {
      if (mounted) {
        final current = progressMap[widget.task.trackId];
        if (liveProgress != current) {
          setState(() => liveProgress = current);
        }
      }
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final task = widget.task;
    final db = widget.db;

    // Use live progress from stream, fallback to DB progress
    double progress = 0.0;
    if (liveProgress != null && liveProgress! >= 0) {
      progress = liveProgress!;
    } else if (task.totalBytes > 0 && task.downloadedBytes > 0) {
      progress = task.downloadedBytes / task.totalBytes;
    }

    final bool isDownloading =
        task.status == 'downloading' ||
        (liveProgress != null && liveProgress! > 0 && liveProgress! < 1.0);
    final bool isCompleted =
        task.status == 'completed' ||
        (liveProgress != null && liveProgress! >= 1.0);
    final bool isFailed =
        task.status == 'failed' || (liveProgress != null && liveProgress! < 0);
    final bool isPending = task.status == 'pending';

    Color statusColor = cs.primary;
    IconData statusIcon = Icons.downloading_rounded;
    String statusLabel = 'Downloading';

    if (isCompleted) {
      statusColor = cs.tertiary;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Completed';
      progress = 1.0;
    } else if (isFailed) {
      statusColor = cs.error;
      statusIcon = Icons.error_rounded;
      statusLabel = 'Failed';
    } else if (isPending) {
      statusColor = cs.secondary;
      statusIcon = Icons.schedule_rounded;
      statusLabel = 'Queued';
    } else if (isDownloading) {
      statusLabel = '${(progress * 100).toInt()}%';
    }

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      onDismissed: (_) {
        if (task.status == 'completed') {
          db.archiveTask(task.id);
        } else {
          db.deleteTask(task.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: task.coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: task.coverUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            memCacheWidth: 104,
                            memCacheHeight: 104,
                            placeholder: (_, a) => _placeholder(cs),
                          )
                        : _placeholder(cs),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.trackTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${task.artistName} • ${task.albumTitle}',
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
                  if (isDownloading) ...[
                    // Live wavy circular progress with percentage
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3,
                            backgroundColor: cs.surfaceContainerHighest,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}',
                          style: tt.labelSmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: cs.error,
                      ),
                      tooltip: 'Cancel',
                      onPressed: () => ref
                          .read(downloadServiceProvider)
                          .cancelDownload(task.trackId),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ] else ...[
                    Column(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 24),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          style: tt.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // M3 Linear progress bar at bottom of card
            if (isDownloading)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  color: cs.primary,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            if (isPending)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                child: LinearProgressIndicator(
                  value: null,
                  minHeight: 4,
                  color: cs.secondary,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme cs) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(Icons.music_note, color: cs.onSurfaceVariant),
  );
}
