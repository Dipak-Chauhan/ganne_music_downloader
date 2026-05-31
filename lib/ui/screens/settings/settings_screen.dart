import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/service_providers.dart';
import '../../../data/providers/settings_provider.dart';
import '../../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── About Section ──
          _SectionHeader(title: 'About', cs: cs, tt: tt),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: Icon(Icons.album, color: cs.primary),
              title: Text(AppConstants.appName, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              subtitle: Text(AppConstants.appTagline, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)),
                child: Text('v1.0.0', style: tt.labelSmall?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Aesthetics Theme Section ──
          _SectionHeader(title: 'Aesthetics', cs: cs, tt: tt),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Personalize Ganne\'s accent color palette', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(height: 12),
          _buildAccentSelector(context, ref, cs, tt),

          const SizedBox(height: 24),

          // ── Output Settings ──
          _SectionHeader(title: 'Output Settings', cs: cs, tt: tt),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text('Change the way your music is saved', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ),
          const SizedBox(height: 12),

          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              // Output Codec
              ListTile(
                leading: Icon(Icons.audiotrack_outlined, color: cs.onSurfaceVariant),
                title: Text('Output Codec', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'flac', label: Text('FLAC')),
                    ButtonSegment(value: 'mp3', label: Text('MP3')),
                  ],
                  selected: {settings.outputCodec},
                  onSelectionChanged: (val) => settingsNotifier.setOutputCodec(val.first),
                  showSelectedIcon: false,
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    textStyle: WidgetStatePropertyAll(tt.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              _divider(cs),

              // Max Download Quality
              ListTile(
                leading: Icon(Icons.high_quality_outlined, color: cs.onSurfaceVariant),
                title: Text('Max Download Quality', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  settings.outputCodec == 'mp3' ? '320 kbps' : _qualityLabel(settings.maxQuality),
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                trailing: settings.outputCodec == 'mp3'
                    ? null
                    : PopupMenuButton<String>(
                        initialValue: settings.maxQuality,
                        onSelected: (v) => settingsNotifier.setMaxQuality(v),
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: '6', child: Text('16-Bit • 44.1 kHz')),
                          PopupMenuItem(value: '7', child: Text('24-Bit • 96 kHz')),
                          PopupMenuItem(value: '27', child: Text('24-Bit • 192 kHz')),
                        ],
                        child: Chip(
                          label: Text(_qualityLabel(settings.maxQuality)),
                          avatar: Icon(Icons.expand_more, size: 18, color: cs.onSurfaceVariant),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
              ),
              _divider(cs),

              // Apply Metadata
              SwitchListTile(
                secondary: Icon(Icons.label_outlined, color: cs.onSurfaceVariant),
                title: Text('Apply metadata', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Tag songs with cover art, album information, etc.', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                value: settings.applyMetadata,
                onChanged: settingsNotifier.toggleMetadata,
              ),
              _divider(cs),

              // Allow Explicit Content
              SwitchListTile(
                secondary: Icon(Icons.explicit_outlined, color: cs.onSurfaceVariant),
                title: Text('Allow explicit content', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text('Show explicit songs in search results', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                value: settings.allowExplicit,
                onChanged: settingsNotifier.toggleExplicit,
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Downloads Section ──
          _SectionHeader(title: 'Downloads', cs: cs, tt: tt),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              // Download Location with directory picker
              ListTile(
                leading: Icon(Icons.folder_outlined, color: cs.onSurfaceVariant),
                title: Text('Download Location', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(ref.watch(downloadServiceProvider).baseMusicDir, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                onTap: () async {
                  final path = await FilePicker.platform.getDirectoryPath(
                    dialogTitle: 'Select Download Folder',
                  );
                  if (path != null) {
                    ref.read(downloadServiceProvider).setDownloadPath(path);
                    final storage = ref.read(secureStorageProvider);
                    await storage.writeKey('download_path', path);
                    // Force rebuild
                    (context as Element).markNeedsBuild();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download path set to: $path')));
                    }
                  }
                },
              ),
              _divider(cs),

              // Album Download Mode
              SwitchListTile(
                secondary: Icon(Icons.archive_outlined, color: cs.onSurfaceVariant),
                title: Text('ZIP album downloads', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  settings.zipAlbums ? 'Albums saved as ZIP archives' : 'Albums saved as individual songs',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                value: settings.zipAlbums,
                onChanged: settingsNotifier.toggleZipAlbums,
              ),
            ]),
          ),

          const SizedBox(height: 24),

          // ── Account Section ──
          _SectionHeader(title: 'Account', cs: cs, tt: tt),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: cs.error),
              title: Text('Logout', style: tt.titleSmall?.copyWith(color: cs.error, fontWeight: FontWeight.w600)),
              subtitle: Text('Clear credentials and return to login', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    icon: Icon(Icons.logout_rounded, color: cs.error),
                    title: const Text('Logout'),
                    content: const Text('Are you sure? You will need to re-enter your Qobuz API credentials.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: cs.error),
                        onPressed: () { Navigator.pop(ctx); ref.read(authProvider.notifier).logout(); },
                        child: Text('Logout', style: TextStyle(color: cs.onError)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAccentSelector(BuildContext context, WidgetRef ref, ColorScheme cs, TextTheme tt) {
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);

    final accents = [
      {'id': 'purple', 'name': 'Violet', 'color': const Color(0xFF7C4DFF)},
      {'id': 'ocean', 'name': 'Ocean', 'color': const Color(0xFF00B0FF)},
      {'id': 'emerald', 'name': 'Emerald', 'color': const Color(0xFF00E676)},
      {'id': 'crimson', 'name': 'Crimson', 'color': const Color(0xFFD50000)},
      {'id': 'sunset', 'name': 'Sunset', 'color': const Color(0xFFFF6D00)},
      {'id': 'sakura', 'name': 'Sakura', 'color': const Color(0xFFFF4081)},
      {'id': 'dynamic', 'name': 'Dynamic', 'color': Colors.transparent},
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: accents.map((acc) {
            final id = acc['id'] as String;
            final name = acc['name'] as String;
            final isSelected = settings.themeAccent == id;
            final color = acc['color'] as Color;

            return InkWell(
              onTap: () => settingsNotifier.setThemeAccent(id),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? cs.primaryContainer 
                      : cs.surfaceContainerHighest.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cs.primary : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (id == 'dynamic')
                      Icon(
                        Icons.wallpaper_rounded,
                        size: 16,
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
                      )
                    else
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withAlpha(200), width: 1),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.check_circle, size: 14, color: cs.primary),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  static String _qualityLabel(String id) {
    switch (id) {
      case '6': return '16-Bit • 44.1 kHz';
      case '7': return '24-Bit • 96 kHz';
      case '27': return '24-Bit • 192 kHz';
      default: return id;
    }
  }

  static Widget _divider(ColorScheme cs) => Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant.withAlpha(60));
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme cs;
  final TextTheme tt;
  const _SectionHeader({required this.title, required this.cs, required this.tt});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: Text(title, style: tt.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w600)),
  );
}
