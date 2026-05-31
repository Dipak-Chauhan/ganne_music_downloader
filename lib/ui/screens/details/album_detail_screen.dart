import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/qobuz_models.dart';
import '../../../data/providers/service_providers.dart';
import '../../../services/download/download_service.dart';

class AlbumDetailScreen extends ConsumerStatefulWidget {
  final QobuzAlbum album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
  FetchedAlbumResponse? _fetchedData;
  bool _isLoading = true;
  String? _error;
  String _selectedQuality = '27';

  Map<int, double> _downloadProgress = {};
  StreamSubscription? _progressSub;

  final List<Map<String, String>> _qualities = const [
    {'id': '5', 'label': 'MP3', 'detail': '320 kbps'},
    {'id': '6', 'label': 'FLAC', 'detail': '16-Bit / 44.1 kHz'},
    {'id': '7', 'label': 'FLAC', 'detail': '24-Bit / 96 kHz'},
    {'id': '27', 'label': 'FLAC', 'detail': '24-Bit / 192 kHz'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchAlbumDetails();
    _subscribeToProgress();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  void _subscribeToProgress() {
    final service = ref.read(downloadServiceProvider);
    _downloadProgress = service.currentProgress;
    _progressSub = service.progressStream.listen((progress) {
      if (mounted) setState(() => _downloadProgress = progress);
    });
  }

  void _fetchAlbumDetails() async {
    try {
      final data = await ref
          .read(qobuzServiceProvider)
          .getAlbumInfo(widget.album.id!);
      if (mounted)
        setState(() {
          _fetchedData = data;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
    }
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  void _queueTrack(QobuzTrack track) {
    final service = ref.read(downloadServiceProvider);

    // Format complex artist string
    final artistNames =
        track.album?.artists?.map((a) => a.name).toList() ??
        widget.album.artists?.map((a) => a.name).toList();

    final artistString = DownloadService.joinArtists(
      artistNames,
      fallback: track.performer?.name ?? widget.album.artist?.name ?? 'Unknown',
    );

    final albumArtist = widget.album.artist?.name ?? artistString;

    service.queueTrack(
      trackId: track.id,
      trackTitle: track.title,
      albumTitle: widget.album.title,
      artistName: artistString,
      albumArtist: albumArtist,
      trackVersion: track.version ?? widget.album.version,
      trackNumber: track.trackNumber,
      year: widget.album.releasedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(
              widget.album.releasedAt! * 1000,
            ).year
          : null,
      genre: widget.album.genre?.name,
      coverUrl: widget.album.getCoverLargeUrl(),
      quality: _selectedQuality,
    );
  }

  void _showDownloadOptions() {
    if (_fetchedData?.tracks?.items == null) return;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Download Album',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                widget.album.title,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _downloadAlbumIndividual();
                },
                icon: const Icon(Icons.queue_music),
                label: const Text('Download individually'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _downloadAlbumZip();
                },
                icon: const Icon(Icons.folder_zip_outlined),
                label: const Text('Download as ZIP archive'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _downloadAlbumZip() {
    if (_fetchedData?.tracks?.items == null) return;

    ref
        .read(downloadServiceProvider)
        .downloadAlbumAsZip(
          album: widget.album,
          fetchedData: _fetchedData!,
          qualityId: _selectedQuality,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Album ZIP download started...')),
    );
  }

  void _downloadAlbumIndividual() {
    if (_fetchedData?.tracks?.items == null) return;

    for (var track in _fetchedData!.tracks!.items!) {
      _queueTrack(track);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_fetchedData!.tracks!.items!.length} tracks queued!'),
        action: SnackBarAction(
          label: 'View Queue',
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: cs.error),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _error!,
                      style: tt.bodyMedium?.copyWith(color: cs.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // ── Collapsing App Bar (M3 Large Top App Bar) ──
                SliverAppBar.large(
                  pinned: true,
                  expandedHeight: 320,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.album.getFullResImageUrl(),
                          fit: BoxFit.cover,
                          placeholder: (_, _a) =>
                              Container(color: cs.surfaceContainerHighest),
                          errorWidget: (_, _a, _b) => Container(
                            color: cs.surfaceContainerHighest,
                            child: Center(
                              child: Icon(
                                Icons.album,
                                size: 64,
                                color: cs.outlineVariant,
                              ),
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                cs.surface.withAlpha(200),
                                cs.surface,
                              ],
                              stops: const [0.3, 0.75, 1.0],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Album Metadata (M3 Chips) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.album.artist?.name ?? 'Unknown Artist',
                          style: tt.titleMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (widget.album.tracksCount != null)
                              Chip(
                                avatar: Icon(
                                  Icons.queue_music,
                                  size: 16,
                                  color: cs.onSurfaceVariant,
                                ),
                                label: Text(
                                  '${widget.album.tracksCount} tracks',
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (widget.album.duration != null)
                              Chip(
                                avatar: Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: cs.onSurfaceVariant,
                                ),
                                label: Text(
                                  _formatDuration(widget.album.duration),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (widget.album.hires == true)
                              Chip(
                                avatar: Icon(
                                  Icons.high_quality,
                                  size: 16,
                                  color: cs.onTertiaryContainer,
                                ),
                                label: Text(
                                  'Hi-Res',
                                  style: TextStyle(
                                    color: cs.onTertiaryContainer,
                                  ),
                                ),
                                backgroundColor: cs.tertiaryContainer,
                                side: BorderSide.none,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            if (widget.album.maximumBitDepth != null)
                              Chip(
                                avatar: Icon(
                                  Icons.memory,
                                  size: 16,
                                  color: cs.onSurfaceVariant,
                                ),
                                label: Text(
                                  '${widget.album.maximumBitDepth}-Bit / ${widget.album.maximumSamplingRate} kHz',
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Quality + Download All ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownMenu<String>(
                            initialSelection: _selectedQuality,
                            label: const Text('Quality'),
                            onSelected: (val) {
                              if (val != null)
                                setState(() => _selectedQuality = val);
                            },
                            dropdownMenuEntries: _qualities
                                .map(
                                  (q) => DropdownMenuEntry(
                                    value: q['id']!,
                                    label: '${q['label']} ${q['detail']}',
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: _showDownloadOptions,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Download'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Divider(indent: 20, endIndent: 20),
                ),

                // ── Track List ──
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final track = _fetchedData!.tracks!.items![index];
                      final progress = _downloadProgress[track.id];
                      final isDownloading =
                          progress != null && progress >= 0 && progress < 1.0;
                      final isCompleted = progress != null && progress >= 1.0;
                      final isFailed = progress != null && progress < 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                _queueTrack(track);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('"${track.title}" queued!'),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  8,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text(
                                        '${track.trackNumber ?? index + 1}',
                                        style: tt.titleSmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            track.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: tt.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (track.performer != null &&
                                              track.performer?.name !=
                                                  widget.album.artist?.name)
                                            Text(
                                              track.performer!.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: tt.bodySmall?.copyWith(
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      _formatDuration(track.duration),
                                      style: tt.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    // Progress indicator
                                    if (isDownloading)
                                      SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: progress,
                                              strokeWidth: 3,
                                              backgroundColor:
                                                  cs.surfaceContainerHighest,
                                            ),
                                            Text(
                                              '${(progress * 100).toInt()}',
                                              style: tt.labelSmall?.copyWith(
                                                fontSize: 8,
                                                fontWeight: FontWeight.w700,
                                                color: cs.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else if (isCompleted)
                                      Icon(
                                        Icons.check_circle_rounded,
                                        color: cs.tertiary,
                                        size: 22,
                                      )
                                    else if (isFailed)
                                      Icon(
                                        Icons.error_rounded,
                                        color: cs.error,
                                        size: 22,
                                      )
                                    else
                                      Icon(
                                        Icons.download_outlined,
                                        color: cs.primary,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (isDownloading)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16),
                                ),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 3,
                                  color: cs.primary,
                                  backgroundColor: cs.surfaceContainerHighest,
                                ),
                              ),
                          ],
                        ),
                      );
                    }, childCount: _fetchedData!.tracks?.items?.length ?? 0),
                  ),
                ),
              ],
            ),
    );
  }
}
