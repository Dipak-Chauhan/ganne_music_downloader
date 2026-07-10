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
import '../../widgets/glassmorphic_container.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _screens = [
      DashboardScreen(
        onNavigate: (idx) {
          if ((_currentIndex - idx).abs() == 1) {
            _pageController.animateToPage(
              idx,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
            );
          } else {
            _pageController.jumpToPage(idx);
          }
          setState(() => _currentIndex = idx);
        },
      ),
      const SearchScreen(),
      const QueueScreen(),
      const LibraryScreen(),
      const SettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          RepaintBoundary(
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (idx) {
                setState(() => _currentIndex = idx);
              },
              children: _screens,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 80.0 + MediaQuery.of(context).padding.bottom,
            child: RepaintBoundary(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DownloadBar(
                    downloadService: ref.read(downloadServiceProvider),
                  ),
                  const MiniPlayer(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: RepaintBoundary(
        child: GlassmorphicContainer(
          borderRadius: 20,
          blur: 20,
          color: isDark ? cs.surface.withAlpha(140) : cs.surface.withAlpha(180),
          borderColor: cs.outlineVariant.withAlpha(40),
          borderWidth: 0.5,
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          boxShadow: const [],
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: _currentIndex,
            onDestinationSelected: (idx) {
              if ((_currentIndex - idx).abs() == 1) {
                _pageController.animateToPage(
                  idx,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                );
              } else {
                _pageController.jumpToPage(idx);
              }
              setState(() => _currentIndex = idx);
            },
            animationDuration: const Duration(milliseconds: 300),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.downloading_outlined),
                selectedIcon: Icon(Icons.downloading),
                label: 'Queue',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Isolated download bar that rebuilds independently via StreamBuilder
/// instead of triggering setState on the parent MainNavigationScreen.
class _DownloadBar extends StatelessWidget {
  final DownloadService downloadService;

  const _DownloadBar({required this.downloadService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ActiveDownloadInfo?>(
      stream: downloadService.activeDownloadStream,
      initialData: downloadService.activeDownload,
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (info == null) return const SizedBox.shrink();

        final cs = Theme.of(context).colorScheme;
        final tt = Theme.of(context).textTheme;
        final percent = (info.progress * 100).toInt();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: GlassmorphicContainer(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    // Cover art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: info.coverUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: info.coverUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              placeholder: (_, _) => Container(
                                width: 44,
                                height: 44,
                                color: cs.surfaceContainerHighest,
                                child: Icon(
                                  Icons.music_note,
                                  size: 20,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Container(
                              width: 44,
                              height: 44,
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note,
                                size: 20,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                    ),
                    const SizedBox(width: 14),
                    // Track info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            info.trackTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.labelLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${info.artistName} • ${info.albumTitle}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Percentage indicator
                    Text(
                      '$percent%',
                      style: tt.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // M3 Rounded Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: info.progress,
                    minHeight: 5,
                    color: cs.primary,
                    backgroundColor: cs.surfaceContainerHighest.withAlpha(120),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
