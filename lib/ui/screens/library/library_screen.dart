import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import '../../../data/local/database.dart';
import '../../../data/providers/service_providers.dart';
import '../../../services/player/player_service.dart';
import '../../widgets/glassmorphic_container.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent'; // 'recent', 'title', 'artist'
  final Set<int> _selectedTaskIds = {};
  bool _isMultiSelectMode = false;
  late final Stream<List<DownloadTask>> _tasksStream;

  @override
  void initState() {
    super.initState();
    _tasksStream = ref.read(databaseProvider).watchCompletedTasks();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DownloadTask> _filterAndSortTasks(List<DownloadTask> tasks) {
    // 1. Filter
    var filtered = tasks.where((task) {
      if (_searchQuery.isEmpty) return true;
      final title = task.trackTitle.toLowerCase();
      final artist = task.artistName.toLowerCase();
      final album = task.albumTitle.toLowerCase();
      return title.contains(_searchQuery) ||
          artist.contains(_searchQuery) ||
          album.contains(_searchQuery);
    }).toList();

    // 2. Sort
    if (_sortBy == 'recent') {
      filtered.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    } else if (_sortBy == 'title') {
      filtered.sort((a, b) => a.trackTitle.compareTo(b.trackTitle));
    } else if (_sortBy == 'artist') {
      filtered.sort((a, b) => a.artistName.compareTo(b.artistName));
    }

    return filtered;
  }

  double _getFileSizeMB(String? path) {
    if (path == null) return 0.0;
    try {
      final file = File(path);
      if (file.existsSync()) {
        return file.lengthSync() / (1024 * 1024);
      }
    } catch (_) {}
    return 0.0;
  }

  Widget _buildQualityBadge(String quality, ColorScheme cs, TextTheme tt) {
    String label = '';
    Color bgColor = Colors.transparent;
    Color textColor = Colors.transparent;
    switch (quality) {
      case '5':
        label = 'MP3 320k';
        bgColor = cs.surfaceContainerHighest;
        textColor = cs.onSurfaceVariant;
        break;
      case '6':
        label = 'FLAC 16-Bit';
        bgColor = cs.secondaryContainer;
        textColor = cs.onSecondaryContainer;
        break;
      case '7':
        label = 'FLAC 24-Bit / 96k';
        bgColor = cs.tertiaryContainer;
        textColor = cs.onTertiaryContainer;
        break;
      case '27':
        label = 'FLAC 24-Bit / 192k';
        bgColor = cs.primaryContainer;
        textColor = cs.onPrimaryContainer;
        break;
      default:
        label = 'Lossless';
        bgColor = cs.secondaryContainer;
        textColor = cs.onSecondaryContainer;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 10,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildDetailRowWithIcon({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme cs,
    required TextTheme tt,
    bool isPath = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: cs.primary.withAlpha(150)),
          const SizedBox(width: 12),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: isPath ? 3 : 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                fontFamily: isPath ? 'monospace' : null,
                fontSize: isPath ? 10 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrackDetails(
    DownloadTask task,
    List<DownloadTask> playlist,
    ColorScheme cs,
    TextTheme tt,
  ) {
    final size = _getFileSizeMB(task.savePath);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16 +
                MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).padding.bottom,
          ),
          child: GlassmorphicContainer(
            borderRadius: 24,
            blur: 20,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            borderColor: cs.outlineVariant.withAlpha(45),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cover & Track Info Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: task.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: task.coverUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note,
                                size: 36,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            task.trackTitle,
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            task.artistName,
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          _buildQualityBadge(task.quality, cs, tt),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh.withAlpha(120),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withAlpha(40),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRowWithIcon(
                        icon: Icons.album_outlined,
                        label: 'Album',
                        value: task.albumTitle,
                        cs: cs,
                        tt: tt,
                      ),
                      _buildDetailRowWithIcon(
                        icon: Icons.music_note_outlined,
                        label: 'Genre',
                        value: task.genre ?? 'Unknown',
                        cs: cs,
                        tt: tt,
                      ),
                      _buildDetailRowWithIcon(
                        icon: Icons.calendar_month_outlined,
                        label: 'Year',
                        value: task.year != null
                            ? task.year.toString()
                            : 'Unknown',
                        cs: cs,
                        tt: tt,
                      ),
                      _buildDetailRowWithIcon(
                        icon: Icons.high_quality_outlined,
                        label: 'Quality',
                        value: _getQualityLabel(task.quality),
                        cs: cs,
                        tt: tt,
                      ),
                      if (size > 0)
                        _buildDetailRowWithIcon(
                          icon: Icons.data_usage_outlined,
                          label: 'File Size',
                          value: '${size.toStringAsFixed(2)} MB',
                          cs: cs,
                          tt: tt,
                        ),
                      _buildDetailRowWithIcon(
                        icon: Icons.folder_open_outlined,
                        label: 'Save Path',
                        value: task.savePath ?? 'Unknown',
                        cs: cs,
                        tt: tt,
                        isPath: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Actions
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref
                        .read(audioPlayerProvider.notifier)
                        .playTrack(task, playlist);
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play In-App'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          if (task.savePath != null) {
                            final result = await OpenFilex.open(task.savePath!);
                            if (result.type != ResultType.done && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not open: ${result.message}',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: const Text(
                          'Open File',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          fixedSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: cs.onSurface,
                          side: BorderSide(
                            color: cs.outlineVariant.withAlpha(120),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDelete(task);
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text(
                          'Delete',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          fixedSize: const Size.fromHeight(44),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          foregroundColor: cs.error,
                          side: BorderSide(
                            color: cs.error.withAlpha(120),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getQualityLabel(String qualityId) {
    switch (qualityId) {
      case '5':
        return 'MP3 (320 kbps)';
      case '6':
        return 'FLAC (16-Bit / 44.1 kHz)';
      case '7':
        return 'FLAC (24-Bit / 96 kHz)';
      case '27':
        return 'FLAC (24-Bit / 192 kHz)';
      default:
        return 'FLAC Lossless';
    }
  }

  void _confirmDelete(DownloadTask task) {
    final cs = Theme.of(context).colorScheme;
    final db = ref.read(databaseProvider);
    bool deleteFromStorage = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            icon: Icon(Icons.delete_forever_rounded, color: cs.error, size: 36),
            title: const Text('Delete Track'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to remove "${task.trackTitle}"?',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text('Also delete file from storage'),
                  subtitle: Text(
                    deleteFromStorage
                        ? 'Audio file will be permanently deleted from device'
                        : 'Audio file will be kept on your device storage',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                  ),
                  value: deleteFromStorage,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => deleteFromStorage = val);
                    }
                  },
                  activeColor: cs.error,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: cs.error),
                onPressed: () async {
                  Navigator.pop(ctx);

                  // 0. Stop audio player if currently playing the deleted track
                  final playerState = ref.read(audioPlayerProvider);
                  if (playerState.currentTrack?.trackId == task.trackId) {
                    await ref.read(audioPlayerProvider.notifier).stop();
                  }

                  // 1. Delete from disk if requested
                  if (deleteFromStorage && task.savePath != null) {
                    try {
                      final file = File(task.savePath!);
                      if (await file.exists()) {
                        await file.delete();
                        debugPrint('Deleted file: ${task.savePath}');
                        await ref
                            .read(downloadServiceProvider)
                            .deleteEmptyDirs(task.savePath!);
                      }
                    } catch (e) {
                      debugPrint('Failed to delete file on disk: $e');
                    }
                  }

                  // 2. Delete from database
                  await db.deleteTask(task.id);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          deleteFromStorage
                              ? 'Deleted "${task.trackTitle}" from library and storage'
                              : 'Removed "${task.trackTitle}" from library',
                        ),
                      ),
                    );
                  }
                },
                child: Text(
                  deleteFromStorage
                      ? 'Delete Everywhere'
                      : 'Delete from Library',
                  style: TextStyle(color: cs.onError),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _toggleSelection(int taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  void _confirmClearSelected() {
    final cs = Theme.of(context).colorScheme;
    final db = ref.read(databaseProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_sweep_rounded, color: cs.error, size: 36),
        title: const Text('Clear Selected'),
        content: Text(
          'Remove ${_selectedTaskIds.length} selected tracks from the library list? Audio files on storage will NOT be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in _selectedTaskIds) {
                await db.deleteTask(id);
              }
              setState(() {
                _selectedTaskIds.clear();
                _isMultiSelectMode = false;
              });
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected() {
    final cs = Theme.of(context).colorScheme;
    final db = ref.read(databaseProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_forever_rounded, color: cs.error, size: 36),
        title: const Text('Delete Selected'),
        content: Text(
          'Are you sure you want to permanently delete ${_selectedTaskIds.length} selected tracks? This will permanently delete the audio files from your device storage and database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);

              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Deleting selected tracks...'),
                  duration: Duration(seconds: 2),
                ),
              );

              // 0. Stop player if playing any of the selected tracks
              final playerState = ref.read(audioPlayerProvider);
              if (playerState.currentTrack != null &&
                  _selectedTaskIds.contains(playerState.currentTrack!.id)) {
                await ref.read(audioPlayerProvider.notifier).stop();
              }

              // 1. Fetch completed tasks
              final completedTasks = await db.watchCompletedTasks().first;
              final selectedTasks = completedTasks
                  .where((t) => _selectedTaskIds.contains(t.id))
                  .toList();

              // 2. Delete files from storage
              int deleteCount = 0;
              for (final task in selectedTasks) {
                if (task.savePath != null) {
                  try {
                    final file = File(task.savePath!);
                    if (await file.exists()) {
                      await file.delete();
                      deleteCount++;
                      await ref
                          .read(downloadServiceProvider)
                          .deleteEmptyDirs(task.savePath!);
                    }
                  } catch (e) {
                    debugPrint('Failed to delete file from disk: $e');
                  }
                }
              }

              // 3. Delete database records
              for (final id in _selectedTaskIds) {
                await db.deleteTask(id);
              }

              setState(() {
                _selectedTaskIds.clear();
                _isMultiSelectMode = false;
              });

              if (mounted) {
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'Deleted $deleteCount files from storage and cleared selected logs',
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Delete Everywhere',
              style: TextStyle(color: cs.onError),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final db = ref.watch(databaseProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: _isMultiSelectMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _selectedTaskIds.clear();
                    _isMultiSelectMode = false;
                  });
                },
              ),
              title: Text('${_selectedTaskIds.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Clear Selected',
                  onPressed: _confirmClearSelected,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                  ),
                  tooltip: 'Delete Selected',
                  onPressed: _confirmDeleteSelected,
                ),
              ],
            )
          : AppBar(
              title: const Text('Library'),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (value == 'clear_all') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          icon: Icon(
                            Icons.delete_sweep_rounded,
                            color: cs.error,
                            size: 36,
                          ),
                          title: const Text('Clear All'),
                          content: const Text(
                            'Clear all completed tracks from the library list? Audio files on your device storage will NOT be deleted.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () {
                                db.clearCompleted();
                                Navigator.pop(ctx);
                              },
                              child: const Text('Clear List'),
                            ),
                          ],
                        ),
                      );
                    } else if (value == 'delete_all') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          icon: Icon(
                            Icons.delete_forever_rounded,
                            color: cs.error,
                            size: 36,
                          ),
                          title: const Text('Delete All'),
                          content: const Text(
                            'Are you sure you want to permanently delete all completed tracks? This will permanently delete the audio files from your device storage and database.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.error,
                              ),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);

                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Deleting all downloaded tracks...',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                // 1. Fetch completed tasks
                                final completedTasks = await db
                                    .watchCompletedTasks()
                                    .first;

                                // 0. Stop player if playing any completed track
                                final playerState = ref.read(
                                  audioPlayerProvider,
                                );
                                if (playerState.currentTrack != null &&
                                    completedTasks.any(
                                      (t) =>
                                          t.id == playerState.currentTrack!.id,
                                    )) {
                                  await ref
                                      .read(audioPlayerProvider.notifier)
                                      .stop();
                                }

                                // 2. Delete all files from storage
                                int deleteCount = 0;
                                for (final task in completedTasks) {
                                  if (task.savePath != null) {
                                    try {
                                      final file = File(task.savePath!);
                                      if (await file.exists()) {
                                        await file.delete();
                                        deleteCount++;
                                        await ref
                                            .read(downloadServiceProvider)
                                            .deleteEmptyDirs(task.savePath!);
                                      }
                                    } catch (e) {
                                      debugPrint(
                                        'Failed to delete file from disk: $e',
                                      );
                                    }
                                  }
                                }

                                // 3. Delete from database
                                await db.clearCompleted();

                                if (mounted) {
                                  messenger.hideCurrentSnackBar();
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Deleted $deleteCount files from storage and cleared library',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                'Delete Everywhere',
                                style: TextStyle(color: cs.onError),
                              ),
                            ),
                          ],
                        ),
                      );
                    } else if (value == 'reset_storage') {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          icon: const Icon(
                            Icons.cleaning_services_rounded,
                            color: Colors.orange,
                            size: 36,
                          ),
                          title: const Text('Reset Library Storage'),
                          content: const Text(
                            'Are you sure you want to completely reset the library storage? This will permanently delete all downloaded audio files, ZIP archives, temporary files, and empty folders from your device storage, and clear all database logs. This cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                Navigator.pop(ctx);

                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Resetting library storage...',
                                    ),
                                    duration: Duration(seconds: 2),
                                  ),
                                );

                                await ref
                                    .read(downloadServiceProvider)
                                    .resetLibraryStorage(
                                      onStopPlayer: () {
                                        ref
                                            .read(audioPlayerProvider.notifier)
                                            .stop();
                                      },
                                    );

                                if (mounted) {
                                  messenger.hideCurrentSnackBar();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Library storage reset successfully',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'Reset',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, size: 20),
                          SizedBox(width: 12),
                          Text('Clear List'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_forever_rounded,
                            size: 20,
                            color: Colors.red,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Delete All',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset_storage',
                      child: Row(
                        children: [
                          Icon(
                            Icons.cleaning_services_rounded,
                            size: 20,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Reset Storage',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
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

          final rawTasks = snapshot.data ?? [];

          if (rawTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.library_music_outlined,
                    size: 64,
                    color: cs.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your library is empty',
                    style: tt.titleMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Downloaded music will appear here',
                    style: tt.bodyMedium?.copyWith(color: cs.outlineVariant),
                  ),
                ],
              ),
            );
          }

          // Filter and Sort dynamically
          final tasks = _filterAndSortTasks(rawTasks);

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search title, artist, album...',
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.search, color: cs.onSurfaceVariant),
                  ),
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
                        onPressed: () => _searchController.clear(),
                      ),
                  ],
                ),
              ),

              // Sorting Segmented control
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const totalChipsWidth = 320.0;
                    final fits = constraints.maxWidth >= totalChipsWidth;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: fits
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                      child: Row(
                        children: [
                          FilterChip(
                            selected: _sortBy == 'recent',
                            label: const Text('Recently Added'),
                            onSelected: (selected) {
                              if (selected) setState(() => _sortBy = 'recent');
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _sortBy == 'title',
                            label: const Text('Song A-Z'),
                            onSelected: (selected) {
                              if (selected) setState(() => _sortBy = 'title');
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _sortBy == 'artist',
                            label: const Text('Artist A-Z'),
                            onSelected: (selected) {
                              if (selected) setState(() => _sortBy = 'artist');
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              // Library list
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          'No matching tracks found.',
                          style: tt.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 160),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          final isSelected = _selectedTaskIds.contains(task.id);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: isSelected
                                ? cs.primaryContainer.withAlpha(80)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? cs.primary
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                if (_isMultiSelectMode) {
                                  _toggleSelection(task.id);
                                } else {
                                  _showTrackDetails(task, tasks, cs, tt);
                                }
                              },
                              onLongPress: () {
                                if (!_isMultiSelectMode) {
                                  setState(() {
                                    _isMultiSelectMode = true;
                                    _selectedTaskIds.add(task.id);
                                  });
                                }
                              },
                              child: Padding(
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
                                              placeholder: (_, _a) => Container(
                                                width: 52,
                                                height: 52,
                                                color:
                                                    cs.surfaceContainerHighest,
                                                child: Icon(
                                                  Icons.music_note,
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              width: 52,
                                              height: 52,
                                              color: cs.surfaceContainerHighest,
                                              child: Icon(
                                                Icons.music_note,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                    if (_isMultiSelectMode)
                                      Checkbox(
                                        value: isSelected,
                                        activeColor: cs.primary,
                                        onChanged: (_) =>
                                            _toggleSelection(task.id),
                                      )
                                    else
                                      IconButton.filledTonal(
                                        onPressed: () {
                                          ref
                                              .read(
                                                audioPlayerProvider.notifier,
                                              )
                                              .playTrack(task, tasks);
                                        },
                                        icon: const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 24,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
