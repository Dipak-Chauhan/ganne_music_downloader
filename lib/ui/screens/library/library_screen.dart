import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import '../../../data/local/database.dart';
import '../../../data/providers/service_providers.dart';
import '../../../services/player/player_service.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent'; // 'recent', 'title', 'artist'

  @override
  void initState() {
    super.initState();
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
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover and primary info
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: task.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: task.coverUrl,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 120,
                              height: 120,
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note,
                                size: 48,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.trackTitle,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      task.artistName,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Song details list
              Text(
                'Song Info',
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildDetailRow('Album', task.albumTitle, cs, tt),
              _buildDetailRow('Genre', task.genre ?? 'Unknown', cs, tt),
              _buildDetailRow(
                'Year',
                task.year != null ? task.year.toString() : 'Unknown',
                cs,
                tt,
              ),
              _buildDetailRow(
                'Quality',
                _getQualityLabel(task.quality),
                cs,
                tt,
              ),
              if (size > 0)
                _buildDetailRow(
                  'File Size',
                  '${size.toStringAsFixed(2)} MB',
                  cs,
                  tt,
                ),
              _buildDetailRow(
                'Save Path',
                task.savePath ?? 'Unknown',
                cs,
                tt,
                isPath: true,
              ),

              const SizedBox(height: 24),

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
                  minimumSize: const Size.fromHeight(48),
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
                      label: const Text('Open External'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
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
                      icon: Icon(Icons.delete_outline_rounded, color: cs.error),
                      label: Text('Delete', style: TextStyle(color: cs.error)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        side: BorderSide(color: cs.error.withAlpha(120)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ColorScheme cs,
    TextTheme tt, {
    bool isPath = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
              maxLines: isPath ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface,
                fontFamily: isPath ? 'monospace' : null,
              ),
            ),
          ),
        ],
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

                  // 1. Delete from disk if requested
                  if (deleteFromStorage && task.savePath != null) {
                    try {
                      final file = File(task.savePath!);
                      if (await file.exists()) {
                        await file.delete();
                        debugPrint('Deleted file: ${task.savePath}');
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

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear') {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    icon: Icon(Icons.delete_sweep, color: cs.error),
                    title: const Text('Clear completed logs'),
                    content: const Text(
                      'Clear all completed tracks from the list? Files on disk will NOT be deleted.',
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
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'clear',
                child: Text('Clear completed logs'),
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<List<DownloadTask>>(
        stream: db.watchCompletedTasks(),
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () =>
                                  _showTrackDetails(task, tasks, cs, tt),
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
                                    // In-App play trigger button
                                    IconButton.filledTonal(
                                      onPressed: () {
                                        ref
                                            .read(audioPlayerProvider.notifier)
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
