import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/qobuz_models.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/providers/settings_provider.dart';
import '../../../services/download/download_service.dart';
import '../../../core/utils/app_toast.dart';
import '../details/album_detail_screen.dart';
import '../../widgets/glassmorphic_container.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  SearchResults? _results;
  SearchResults? _suggestions;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _showSuggestions = false;
  String? _error;
  String _searchField = 'albums';
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  final GlobalKey _searchBarKey = GlobalKey();

  late final AnimationController _logoController;
  late final Animation<double> _logoScale;

  List<String> _searchHistory = [];
  final bool _hiResOnly = false;
  String _searchSortOrder = 'default';
  bool _showSortMenu = false;
  int _albumNextOffset = 0;
  int _trackNextOffset = 0;
  int _searchRequestId = 0;
  String _activeQuery = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _logoScale =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 50),
          TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 50),
        ]).animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
        );

    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _searchFocus.addListener(() {
      if (!_searchFocus.hasFocus && _showSuggestions) {
        Future.delayed(const Duration(milliseconds: 250), () {
          if (mounted && !_searchFocus.hasFocus) {
            setState(() => _showSuggestions = false);
          }
        });
      }
    });
  }

  void _loadSearchHistory() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.readKey('search_history');
      if (raw != null && raw.isNotEmpty) {
        setState(() {
          _searchHistory = raw.split('|').where((s) => s.isNotEmpty).toList();
        });
      }
    } catch (_) {}
  }

  void _addToHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _searchHistory.remove(trimmed);
    _searchHistory.insert(0, trimmed);
    if (_searchHistory.length > 8) {
      _searchHistory = _searchHistory.take(8).toList();
    }
    setState(() {});
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.writeKey('search_history', _searchHistory.join('|'));
    } catch (_) {}
  }

  void _removeFromHistory(String item) async {
    _searchHistory.remove(item);
    setState(() {});
    try {
      final storage = ref.read(secureStorageProvider);
      await storage.writeKey('search_history', _searchHistory.join('|'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _logoController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  List<QobuzAlbum> get _filteredAlbums => _getFilteredAlbums();
  List<QobuzTrack> get _filteredTracks => _getFilteredTracks();

  void _onSearchChanged() {
    setState(() {}); // Update clear icon
    final query = _searchController.text.trim();
    if (query.length < 2) {
      _debounce?.cancel();
      setState(() {
        _suggestions = null;
        _showSuggestions = false;
      });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchSuggestions(query);
    });
  }

  void _fetchSuggestions(String query) async {
    try {
      final results = await ref
          .read(qobuzServiceProvider)
          .search(query, limit: 5);
      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _suggestions = results;
          _showSuggestions = true;
        });
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_showSuggestions) {
      setState(() => _showSuggestions = false);
    }
    if (_showSortMenu) {
      setState(() => _showSortMenu = false);
    }
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  int get _currentTotal => _searchField == 'albums'
      ? (_results?.albums?.total ?? 0)
      : (_results?.tracks?.total ?? 0);

  void _onSearch(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) return;
    final requestId = ++_searchRequestId;
    _debounce?.cancel();
    _addToHistory(normalizedQuery);
    setState(() {
      _activeQuery = normalizedQuery;
      _isLoading = true;
      _isLoadingMore = false;
      _error = null;
      _showSuggestions = false;
      _albumNextOffset = 0;
      _trackNextOffset = 0;
    });
    _searchFocus.unfocus();
    try {
      final settings = ref.read(appSettingsProvider);
      final unfilteredResults = await ref
          .read(qobuzServiceProvider)
          .search(normalizedQuery, limit: 50);
      var results = unfilteredResults;

      // Explicit content filter
      if (!settings.allowExplicit) {
        results = SearchResults(
          results.query,
          results.albums != null
              ? AlbumsResult(
                  results.albums!.limit,
                  results.albums!.offset,
                  results.albums!.total,
                  results.albums!.items
                      ?.where((a) => a.parentalWarning != true)
                      .toList(),
                )
              : null,
          results.tracks != null
              ? TracksResult(
                  results.tracks!.limit,
                  results.tracks!.offset,
                  results.tracks!.total,
                  results.tracks!.items
                      ?.where((t) => t.parentalWarning != true)
                      .toList(),
                )
              : null,
        );
      }

      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _results = results;
        _albumNextOffset =
            (unfilteredResults.albums?.offset ?? 0) +
            (unfilteredResults.albums?.items?.length ?? 0);
        _trackNextOffset =
            (unfilteredResults.tracks?.offset ?? 0) +
            (unfilteredResults.tracks?.items?.length ?? 0);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _loadMore() async {
    final searchField = _searchField;
    final offset = searchField == 'albums'
        ? _albumNextOffset
        : _trackNextOffset;
    if (_isLoading ||
        _isLoadingMore ||
        _results == null ||
        offset >= _currentTotal) {
      return;
    }
    final requestId = _searchRequestId;
    final query = _activeQuery;
    if (query.isEmpty) return;
    setState(() => _isLoadingMore = true);
    try {
      final settings = ref.read(appSettingsProvider);
      final unfilteredMore = await ref
          .read(qobuzServiceProvider)
          .search(query, limit: 50, offset: offset);
      var more = unfilteredMore;

      // Explicit content filter
      if (!settings.allowExplicit) {
        more = SearchResults(
          more.query,
          more.albums != null
              ? AlbumsResult(
                  more.albums!.limit,
                  more.albums!.offset,
                  more.albums!.total,
                  more.albums!.items
                      ?.where((a) => a.parentalWarning != true)
                      .toList(),
                )
              : null,
          more.tracks != null
              ? TracksResult(
                  more.tracks!.limit,
                  more.tracks!.offset,
                  more.tracks!.total,
                  more.tracks!.items
                      ?.where((t) => t.parentalWarning != true)
                      .toList(),
                )
              : null,
        );
      }

      if (!mounted ||
          requestId != _searchRequestId ||
          searchField != _searchField) {
        if (mounted && requestId == _searchRequestId) {
          setState(() => _isLoadingMore = false);
        }
        return;
      }
      setState(() {
        if (searchField == 'albums') {
          final returned = unfilteredMore.albums?.items?.length ?? 0;
          _albumNextOffset = returned == 0 ? _currentTotal : offset + returned;
        } else {
          final returned = unfilteredMore.tracks?.items?.length ?? 0;
          _trackNextOffset = returned == 0 ? _currentTotal : offset + returned;
        }
        if (searchField == 'albums' && more.albums?.items != null) {
          final existing = _results!.albums!.items ?? [];
          _results = SearchResults(
            _results!.query,
            AlbumsResult(
              _results!.albums!.limit,
              offset,
              _results!.albums!.total,
              [...existing, ...more.albums!.items!],
            ),
            _results!.tracks,
          );
        } else if (searchField == 'tracks' && more.tracks?.items != null) {
          final existing = _results!.tracks!.items ?? [];
          _results = SearchResults(
            _results!.query,
            _results!.albums,
            TracksResult(
              _results!.tracks!.limit,
              offset,
              _results!.tracks!.total,
              [...existing, ...more.tracks!.items!],
            ),
          );
        }
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted && requestId == _searchRequestId) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _resetSearch() {
    _searchRequestId++;
    _logoController.forward(from: 0);
    setState(() {
      _searchController.clear();
      _results = null;
      _suggestions = null;
      _error = null;
      _searchField = 'albums';
      _showSuggestions = false;
      _albumNextOffset = 0;
      _trackNextOffset = 0;
      _activeQuery = '';
      _isLoading = false;
      _isLoadingMore = false;
    });
  }

  String _formatDuration(int? s) {
    if (s == null || s == 0) return '';
    return "${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}";
  }

  String _formatYear(int? t) {
    if (t == null || t == 0) return '';
    return DateTime.fromMillisecondsSinceEpoch(t * 1000).year.toString();
  }

  int _compareTitles(String first, String second) {
    final normalized = first.toLowerCase().compareTo(second.toLowerCase());
    return normalized != 0 ? normalized : first.compareTo(second);
  }

  int _compareReleaseDates(
    int? first,
    int? second, {
    required bool newestFirst,
  }) {
    final firstIsUnknown = first == null || first <= 0;
    final secondIsUnknown = second == null || second <= 0;
    if (firstIsUnknown || secondIsUnknown) {
      if (firstIsUnknown && secondIsUnknown) return 0;
      return firstIsUnknown ? 1 : -1;
    }
    return newestFirst ? second.compareTo(first) : first.compareTo(second);
  }

  void _downloadTrack(QobuzTrack track) async {
    final settings = ref.read(appSettingsProvider);

    final artistString = DownloadService.artistNameForTrack(track);

    final albumArtist = track.album?.artist?.name ?? artistString;

    final status = await ref
        .read(downloadServiceProvider)
        .queueTrack(
          trackId: track.id,
          trackTitle: track.title,
          albumTitle: track.album?.title ?? 'Unknown Album',
          artistName: artistString,
          albumArtist: albumArtist,
          trackVersion: track.version,
          isrc: track.isrc,
          trackNumber: track.trackNumber,
          discNumber: track.mediaNumber,
          totalTracks: track.album?.tracksCount,
          totalDiscs: track.album?.mediaCount,
          durationSeconds: track.duration,
          year: track.album?.releasedAt != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  track.album!.releasedAt! * 1000,
                ).year
              : null,
          genre: track.album?.genre?.name,
          copyright: track.album?.copyright,
          label: track.album?.label,
          barcode: track.album?.upc,
          coverUrl: track.album?.getCoverLargeUrl() ?? '',
          quality: settings.qualityId,
        );
    if (!mounted) return;
    switch (status) {
      case 'queued':
        AppToast.success(context, '"${track.title}" added to queue');
        break;
      case 'already_in_queue':
        AppToast.warning(context, '"${track.title}" is already in queue');
        break;
      case 'already_downloaded':
        AppToast.info(context, '"${track.title}" was already downloaded');
        break;
    }
  }

  void _downloadAlbum(QobuzAlbum album) {
    if (ref.read(appSettingsProvider).zipAlbums) {
      _downloadAlbumZip(album);
    } else {
      _downloadAlbumIndividual(album);
    }
  }

  void _downloadAlbumIndividual(QobuzAlbum album) async {
    final settings = ref.read(appSettingsProvider);
    try {
      final data = await ref.read(qobuzServiceProvider).getAlbumInfo(album.id!);
      if (data.tracks?.items != null) {
        final albumInfo = data.album ?? album;
        final service = ref.read(downloadServiceProvider);
        int queued = 0;
        int skipped = 0;
        for (var track in data.tracks!.items!) {
          final artistName = DownloadService.artistNameForTrack(
            track,
            album: albumInfo,
          );
          final status = await service.queueTrack(
            trackId: track.id,
            trackTitle: track.title,
            albumTitle: albumInfo.title,
            artistName: artistName,
            albumArtist: albumInfo.artist?.name ?? artistName,
            trackVersion: track.version ?? albumInfo.version,
            isrc: track.isrc,
            trackNumber: track.trackNumber,
            discNumber: track.mediaNumber,
            totalTracks: albumInfo.tracksCount ?? data.tracks?.items?.length,
            totalDiscs: albumInfo.mediaCount,
            durationSeconds: track.duration,
            year: albumInfo.releasedAt != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    albumInfo.releasedAt! * 1000,
                  ).year
                : null,
            genre: albumInfo.genre?.name,
            copyright: albumInfo.copyright,
            label: albumInfo.label,
            barcode: albumInfo.upc,
            coverUrl: albumInfo.getCoverLargeUrl(),
            quality: settings.qualityId,
          );
          if (status == 'queued') {
            queued++;
          } else {
            skipped++;
          }
        }
        if (mounted) {
          if (queued > 0 && skipped == 0) {
            AppToast.success(
              context,
              '$queued tracks from "${album.title}" queued',
            );
          } else if (queued > 0 && skipped > 0) {
            AppToast.info(
              context,
              '$queued queued, $skipped already in library',
            );
          } else {
            AppToast.warning(
              context,
              'All tracks already downloaded or in queue',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed: $e');
      }
    }
  }

  void _downloadAlbumZip(QobuzAlbum album) async {
    final settings = ref.read(appSettingsProvider);
    try {
      final data = await ref.read(qobuzServiceProvider).getAlbumInfo(album.id!);
      final operation = ref
          .read(downloadServiceProvider)
          .downloadAlbumAsZip(
            album: album,
            fetchedData: data,
            qualityId: settings.qualityId,
          );
      if (mounted) {
        AppToast.info(context, 'ZIP download started for "${album.title}"');
      }
      await operation;
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed: $e');
      }
    }
  }

  // Calculate suggestion overlay position from SearchBar key
  double get _suggestionsTop {
    final renderBox =
        _searchBarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return 170;
    final pos = renderBox.localToGlobal(Offset.zero);
    return pos.dy + renderBox.size.height + 4;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hasVisibleQuery = _searchController.text.trim().isNotEmpty;
    final hasResults = hasVisibleQuery && _results != null;
    final isLoading = hasVisibleQuery && _isLoading;
    final error = hasVisibleQuery ? _error : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Listener(
      onPointerDown: (_) {
        if (_showSuggestions) setState(() => _showSuggestions = false);
        if (_showSortMenu) setState(() => _showSortMenu = false);
        _searchFocus.unfocus();
      },
      child: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                    child: GestureDetector(
                      onTap: _resetSearch,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Image.asset(
                          isDark
                              ? 'assets/images/ganne_logo_dark.png'
                              : 'assets/images/ganne_logo_light.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    key: _searchBarKey,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: SearchBar(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onSubmitted: _onSearch,
                      onTap: () {
                        if (_suggestions != null) {
                          setState(() => _showSuggestions = true);
                        }
                      },
                      hintText: 'Search albums, tracks...',
                      leading: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(Icons.search, color: cs.onSurfaceVariant),
                      ),
                      trailing: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, color: cs.onSurfaceVariant),
                            onPressed: _resetSearch,
                          ),
                      ],
                    ),
                  ),
                ),

                if (hasResults || isLoading)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FilterChip(
                            selected: _searchField == 'albums',
                            avatar: Icon(
                              _searchField == 'albums'
                                  ? Icons.album
                                  : Icons.album_outlined,
                              size: 18,
                            ),
                            label: const Text('Albums'),
                            onSelected: (_) {
                              if (_showSuggestions) {
                                setState(() => _showSuggestions = false);
                              }
                              setState(() => _searchField = 'albums');
                            },
                          ),
                          const SizedBox(width: 8),
                          FilterChip(
                            selected: _searchField == 'tracks',
                            avatar: Icon(
                              _searchField == 'tracks'
                                  ? Icons.music_note
                                  : Icons.music_note_outlined,
                              size: 18,
                            ),
                            label: const Text('Tracks'),
                            onSelected: (_) {
                              if (_showSuggestions) {
                                setState(() => _showSuggestions = false);
                              }
                              setState(() => _searchField = 'tracks');
                            },
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              if (_showSuggestions) {
                                setState(() => _showSuggestions = false);
                              }
                              setState(() => _showSortMenu = !_showSortMenu);
                            },
                            child: Chip(
                              avatar: Icon(
                                _searchSortOrder == 'default'
                                    ? Icons.sort
                                    : Icons.filter_list,
                                size: 16,
                                color: _showSortMenu ? cs.primary : null,
                              ),
                              label: Text(
                                _searchSortOrder == 'default'
                                    ? 'Sort'
                                    : _searchSortOrder == 'title'
                                    ? 'By Name'
                                    : _searchSortOrder == 'newest'
                                    ? 'By Newest'
                                    : 'By Oldest',
                                style: TextStyle(
                                  color: _showSortMenu ? cs.primary : null,
                                  fontWeight: _showSortMenu
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                              backgroundColor: _showSortMenu
                                  ? cs.primaryContainer.withAlpha(100)
                                  : null,
                              side: BorderSide(
                                color: _showSortMenu
                                    ? cs.primary.withAlpha(120)
                                    : cs.outlineVariant.withAlpha(80),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (isLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                else if (error != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: cs.error),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              error,
                              textAlign: TextAlign.center,
                              style: tt.bodyMedium?.copyWith(color: cs.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!hasResults)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search,
                            size: 64,
                            color: cs.outlineVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Search for music to get started',
                            style: tt.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (_searchHistory.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Searches',
                                  style: tt.labelLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchHistory.clear();
                                    });
                                    ref
                                        .read(secureStorageProvider)
                                        .writeKey('search_history', '');
                                  },
                                  child: const Text('Clear All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _searchHistory
                                  .map(
                                    (item) => InputChip(
                                      label: Text(item),
                                      onPressed: () {
                                        _searchController.text = item;
                                        _onSearch(item);
                                      },
                                      onDeleted: () => _removeFromHistory(item),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else if (_searchField == 'albums')
                  _buildAlbumsGrid(cs, tt)
                else
                  _buildTracksList(cs, tt),

                if (hasVisibleQuery && _isLoadingMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            if (_showSuggestions && _suggestions != null)
              _buildSuggestionsOverlay(cs, tt),

            if (hasVisibleQuery && _showSortMenu) _buildSortMenuOverlay(cs, tt),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsOverlay(ColorScheme cs, TextTheme tt) {
    final albums = _suggestions?.albums?.items ?? [];
    final tracks = _suggestions?.tracks?.items ?? [];
    if (albums.isEmpty && tracks.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: _suggestionsTop,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: () {}, // Prevent tap propagation
        child: GlassmorphicContainer(
          borderRadius: 16,
          blur: 25.0,
          color: isDark ? cs.surface.withAlpha(140) : cs.surface.withAlpha(200),
          borderColor: cs.primary.withAlpha(35),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: cs.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Quick Results',
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Albums column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Albums',
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...albums
                            .take(5)
                            .map(
                              (album) => InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() => _showSuggestions = false);
                                  _searchFocus.unfocus();
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      pageBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                          ) => AlbumDetailScreen(album: album),
                                      transitionsBuilder:
                                          (
                                            context,
                                            animation,
                                            secondaryAnimation,
                                            child,
                                          ) {
                                            final slideTween =
                                                Tween<Offset>(
                                                  begin: const Offset(
                                                    0.0,
                                                    0.08,
                                                  ),
                                                  end: Offset.zero,
                                                ).chain(
                                                  CurveTween(
                                                    curve: Curves.easeOutCubic,
                                                  ),
                                                );
                                            final fadeTween =
                                                Tween<double>(
                                                  begin: 0.0,
                                                  end: 1.0,
                                                ).chain(
                                                  CurveTween(
                                                    curve: Curves.easeOut,
                                                  ),
                                                );
                                            return SlideTransition(
                                              position: animation.drive(
                                                slideTween,
                                              ),
                                              child: FadeTransition(
                                                opacity: animation.drive(
                                                  fadeTween,
                                                ),
                                                child: child,
                                              ),
                                            );
                                          },
                                      transitionDuration: const Duration(
                                        milliseconds: 350,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    album.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 100,
                    color: cs.outlineVariant.withAlpha(80),
                  ),
                  const SizedBox(width: 12),
                  // Tracks column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tracks',
                          style: tt.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.tertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...tracks
                            .take(5)
                            .map(
                              (track) => InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: () {
                                  setState(() => _showSuggestions = false);
                                  _searchFocus.unfocus();
                                  _downloadTrack(track);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    track.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      ],
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

  Widget _buildSortMenuOverlay(ColorScheme cs, TextTheme tt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      top: _suggestionsTop + 44, // Positioned exactly below the filter row
      left: MediaQuery.of(context).size.width * 0.15,
      right: MediaQuery.of(context).size.width * 0.15,
      child: GestureDetector(
        onTap: () {}, // Prevent tap propagation
        child: GlassmorphicContainer(
          borderRadius: 16,
          blur: 25.0,
          color: isDark ? cs.surface.withAlpha(140) : cs.surface.withAlpha(200),
          borderColor: cs.primary.withAlpha(35),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSortMenuItem(
                icon: Icons.sort_rounded,
                title: 'Default Order',
                value: 'default',
                cs: cs,
                tt: tt,
              ),
              _buildSortMenuItem(
                icon: Icons.title_rounded,
                title: 'Sort by Name',
                value: 'title',
                cs: cs,
                tt: tt,
              ),
              _buildSortMenuItem(
                icon: Icons.calendar_today_rounded,
                title: 'Sort by Newest',
                value: 'newest',
                cs: cs,
                tt: tt,
              ),
              _buildSortMenuItem(
                icon: Icons.history_rounded,
                title: 'Sort by Oldest',
                value: 'oldest',
                cs: cs,
                tt: tt,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSortMenuItem({
    required IconData icon,
    required String title,
    required String value,
    required ColorScheme cs,
    required TextTheme tt,
  }) {
    final isSelected = _searchSortOrder == value;
    return InkWell(
      onTap: () {
        setState(() {
          _searchSortOrder = value;
          _showSortMenu = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: tt.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_rounded, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }

  List<QobuzAlbum> _getFilteredAlbums() {
    var list = List<QobuzAlbum>.from(_results?.albums?.items ?? const []);
    if (_hiResOnly) {
      list = list.where((a) => a.hires == true).toList();
    }
    if (_searchSortOrder == 'title') {
      list.sort((a, b) {
        final title = _compareTitles(a.title, b.title);
        return title != 0 ? title : (a.id ?? '').compareTo(b.id ?? '');
      });
    } else if (_searchSortOrder == 'newest') {
      list.sort((a, b) {
        final releaseDate = _compareReleaseDates(
          a.releasedAt,
          b.releasedAt,
          newestFirst: true,
        );
        return releaseDate != 0
            ? releaseDate
            : _compareTitles(a.title, b.title);
      });
    } else if (_searchSortOrder == 'oldest') {
      list.sort((a, b) {
        final releaseDate = _compareReleaseDates(
          a.releasedAt,
          b.releasedAt,
          newestFirst: false,
        );
        return releaseDate != 0
            ? releaseDate
            : _compareTitles(a.title, b.title);
      });
    }
    return list;
  }

  Widget _buildAlbumsGrid(ColorScheme cs, TextTheme tt) {
    final albums = _filteredAlbums;
    if (albums.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No albums found.',
            style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final album = albums[index];
          return _AlbumCard(
            album: album,
            formatYear: _formatYear,
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AlbumDetailScreen(album: album),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      final slideTween = Tween<Offset>(
                        begin: const Offset(0.0, 0.08),
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic));
                      final fadeTween = Tween<double>(
                        begin: 0.0,
                        end: 1.0,
                      ).chain(CurveTween(curve: Curves.easeOut));
                      return SlideTransition(
                        position: animation.drive(slideTween),
                        child: FadeTransition(
                          opacity: animation.drive(fadeTween),
                          child: child,
                        ),
                      );
                    },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            ),
            onDownload: () => _downloadAlbum(album),
          );
        }, childCount: albums.length),
      ),
    );
  }

  List<QobuzTrack> _getFilteredTracks() {
    var list = List<QobuzTrack>.from(_results?.tracks?.items ?? const []);
    if (_hiResOnly) {
      list = list.where((t) => t.hires == true).toList();
    }
    if (_searchSortOrder == 'title') {
      list.sort((a, b) {
        final title = _compareTitles(a.title, b.title);
        return title != 0 ? title : a.id.compareTo(b.id);
      });
    } else if (_searchSortOrder == 'newest') {
      list.sort((a, b) {
        final releaseDate = _compareReleaseDates(
          a.album?.releasedAt,
          b.album?.releasedAt,
          newestFirst: true,
        );
        return releaseDate != 0
            ? releaseDate
            : _compareTitles(a.title, b.title);
      });
    } else if (_searchSortOrder == 'oldest') {
      list.sort((a, b) {
        final releaseDate = _compareReleaseDates(
          a.album?.releasedAt,
          b.album?.releasedAt,
          newestFirst: false,
        );
        return releaseDate != 0
            ? releaseDate
            : _compareTitles(a.title, b.title);
      });
    }
    return list;
  }

  Widget _buildTracksList(ColorScheme cs, TextTheme tt) {
    final tracks = _filteredTracks;
    if (tracks.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Text(
            'No tracks found.',
            style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final track = tracks[index];
          return _TrackCard(
            track: track,
            formatDuration: _formatDuration,
            onDownload: () => _downloadTrack(track),
          );
        }, childCount: tracks.length),
      ),
    );
  }
}

class _TrackCard extends ConsumerStatefulWidget {
  final QobuzTrack track;
  final String Function(int?) formatDuration;
  final VoidCallback onDownload;

  const _TrackCard({
    required this.track,
    required this.formatDuration,
    required this.onDownload,
  });

  @override
  ConsumerState<_TrackCard> createState() => _TrackCardState();
}

class _TrackCardState extends ConsumerState<_TrackCard> {
  StreamSubscription? _progressSub;
  double? _progress;

  @override
  void initState() {
    super.initState();
    final service = ref.read(downloadServiceProvider);
    _progress = service.currentProgress[widget.track.id];
    _progressSub = service.progressStream.listen((progressMap) {
      final newProgress = progressMap[widget.track.id];
      if (newProgress != _progress) {
        if (mounted) {
          setState(() {
            _progress = newProgress;
          });
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
    final track = widget.track;
    final coverUrl = track.album?.getCoverLargeUrl() ?? '';
    final progress = _progress;
    final isDownloading = progress != null && progress >= 0 && progress < 1.0;
    final isCompleted = progress != null && progress >= 1.0;
    final isFailed = progress != null && progress < 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (track.album != null) {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        AlbumDetailScreen(album: track.album!),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          final slideTween = Tween<Offset>(
                            begin: const Offset(0.0, 0.08),
                            end: Offset.zero,
                          ).chain(CurveTween(curve: Curves.easeOutCubic));
                          final fadeTween = Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).chain(CurveTween(curve: Curves.easeOut));
                          return SlideTransition(
                            position: animation.drive(slideTween),
                            child: FadeTransition(
                              opacity: animation.drive(fadeTween),
                              child: child,
                            ),
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 350),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: coverUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: coverUrl,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            memCacheWidth: 104,
                            memCacheHeight: 104,
                            placeholder: (context, url) =>
                                _CoverPlaceholder(cs: cs),
                          )
                        : _CoverPlaceholder(cs: cs),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          track.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${track.performer?.name ?? track.album?.artist?.name ?? 'Unknown'} • ${widget.formatDuration(track.duration)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (track.hires == true)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Hi-Res',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  _DownloadButton(
                    progress: progress,
                    isDownloading: isDownloading,
                    isCompleted: isCompleted,
                    isFailed: isFailed,
                    onDownload: widget.onDownload,
                    cs: cs,
                    tt: tt,
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
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final ColorScheme cs;
  const _CoverPlaceholder({required this.cs});
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(Icons.music_note, color: cs.onSurfaceVariant),
  );
}

class _DownloadButton extends StatelessWidget {
  final double? progress;
  final bool isDownloading, isCompleted, isFailed;
  final VoidCallback onDownload;
  final ColorScheme cs;
  final TextTheme tt;

  const _DownloadButton({
    required this.progress,
    required this.isDownloading,
    required this.isCompleted,
    required this.isFailed,
    required this.onDownload,
    required this.cs,
    required this.tt,
  });

  @override
  Widget build(BuildContext context) {
    if (isDownloading) {
      return Stack(
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
            '${(progress! * 100).toInt()}',
            style: tt.labelSmall?.copyWith(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: cs.primary,
            ),
          ),
        ],
      );
    }
    if (isCompleted) {
      return Icon(Icons.check_circle_rounded, color: cs.tertiary, size: 24);
    }
    if (isFailed) {
      return IconButton(
        icon: Icon(Icons.refresh_rounded, color: cs.error),
        onPressed: onDownload,
        tooltip: 'Retry',
      );
    }
    return IconButton(
      icon: Icon(Icons.download_rounded, color: cs.primary),
      onPressed: onDownload,
      tooltip: 'Download',
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final QobuzAlbum album;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final String Function(int?) formatYear;

  const _AlbumCard({
    required this.album,
    required this.onTap,
    required this.onDownload,
    required this.formatYear,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final coverUrl = album.getCoverLargeUrl();
    final year = formatYear(album.releasedAt);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Cover
            Hero(
              tag: 'album_art_${album.id}',
              child: coverUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: coverUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 200, // Optimized cache size
                      memCacheHeight: 200,
                      placeholder: (context, url) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.album,
                            size: 40,
                            color: cs.outlineVariant,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: cs.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.album,
                            size: 40,
                            color: cs.outlineVariant,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: cs.surfaceContainerHighest,
                      child: Center(
                        child: Icon(
                          Icons.album,
                          size: 40,
                          color: cs.outlineVariant,
                        ),
                      ),
                    ),
            ),
            // Bottom gradient + text
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(200)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      album.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${album.artist?.name ?? 'Unknown'}${year.isNotEmpty ? ' • $year' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            // Download button — M3 FilledTonal style
            Positioned(
              top: 6,
              left: 6,
              child: IconButton.filledTonal(
                onPressed: onDownload,
                icon: const Icon(Icons.download_rounded, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: cs.surface.withAlpha(200),
                  foregroundColor: cs.onSurface,
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
                tooltip: 'Download album',
              ),
            ),
            // Hi-res badge
            if (album.hires == true)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer.withAlpha(230),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Hi-Res',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onTertiaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
