import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/providers/service_providers.dart';
import '../../../services/download/download_service.dart';
import 'dashboard_screen.dart';
import '../search/search_screen.dart';
import '../queue/queue_screen.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/mini_player.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  ActiveDownloadInfo? _activeDownload;
  StreamSubscription? _activeSub;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigate: (idx) => setState(() => _currentIndex = idx)),
      const SearchScreen(),
      const QueueScreen(),
      const LibraryScreen(),
      const SettingsScreen(),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = ref.read(downloadServiceProvider);
      _activeDownload = service.activeDownload;
      _activeSub = service.activeDownloadStream.listen((info) {
        if (mounted) setState(() => _activeDownload = info);
      });
    });
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          // ── Floating Download Bar ──
          if (_activeDownload != null && _currentIndex != 2) _buildDownloadBar(cs, tt),
          // ── Persistent Mini Player ──
          const MiniPlayer(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        animationDuration: const Duration(milliseconds: 500),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.downloading_outlined), selectedIcon: Icon(Icons.downloading), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildDownloadBar(ColorScheme cs, TextTheme tt) {
    final info = _activeDownload!;
    final percent = (info.progress * 100).toInt();

    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      color: cs.surfaceContainerHigh,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // M3 Linear Progress
          LinearProgressIndicator(
            value: info.progress,
            minHeight: 3,
            color: cs.primary,
            backgroundColor: cs.surfaceContainerHighest,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            child: Row(
              children: [
                // Cover art
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: info.coverUrl.isNotEmpty
                      ? CachedNetworkImage(imageUrl: info.coverUrl, width: 40, height: 40, fit: BoxFit.cover,
                          placeholder: (_, _a) => Container(width: 40, height: 40, color: cs.surfaceContainerHighest, child: Icon(Icons.music_note, size: 18, color: cs.onSurfaceVariant)))
                      : Container(width: 40, height: 40, color: cs.surfaceContainerHighest, child: Icon(Icons.music_note, size: 18, color: cs.onSurfaceVariant)),
                ),
                const SizedBox(width: 12),
                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(info.trackTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                      Text('${info.artistName} • ${info.albumTitle}', maxLines: 1, overflow: TextOverflow.ellipsis, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Percentage
                Text('$percent%', style: tt.labelMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
                // Cancel button
                IconButton(
                  icon: Icon(Icons.close_rounded, color: cs.error, size: 20),
                  tooltip: 'Cancel download',
                  onPressed: () {
                    ref.read(downloadServiceProvider).cancelDownload(info.trackId);
                    setState(() => _activeDownload = null);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
