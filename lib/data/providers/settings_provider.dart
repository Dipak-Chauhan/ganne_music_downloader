import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'service_providers.dart';

class AppSettings {
  final String outputCodec; // 'flac' or 'mp3'
  final String maxQuality; // '5', '6', '7', '27'
  final bool applyMetadata;
  final bool allowExplicit;
  final bool zipAlbums;
  final String downloadLocation;
  final bool customLocationUsesGanneFolder;
  final bool flatDownloads;
  final String
  themeAccent; // 'purple', 'ocean', 'emerald', 'crimson', 'sunset', 'sakura', 'teal', 'amber', 'indigo', 'dynamic'
  final String themeMode; // 'light', 'dark', 'system'
  final bool useAmoled;
  final bool enableBlur;

  const AppSettings({
    this.outputCodec = 'flac',
    this.maxQuality = '27',
    this.applyMetadata = true,
    this.allowExplicit = true,
    this.zipAlbums = false,
    this.downloadLocation = 'music',
    this.customLocationUsesGanneFolder = false,
    this.flatDownloads = false,
    this.themeAccent = 'purple',
    this.themeMode = 'system',
    this.useAmoled = false,
    this.enableBlur = false,
  });

  AppSettings copyWith({
    String? outputCodec,
    String? maxQuality,
    bool? applyMetadata,
    bool? allowExplicit,
    bool? zipAlbums,
    String? downloadLocation,
    bool? customLocationUsesGanneFolder,
    bool? flatDownloads,
    String? themeAccent,
    String? themeMode,
    bool? useAmoled,
    bool? enableBlur,
  }) {
    return AppSettings(
      outputCodec: outputCodec ?? this.outputCodec,
      maxQuality: maxQuality ?? this.maxQuality,
      applyMetadata: applyMetadata ?? this.applyMetadata,
      allowExplicit: allowExplicit ?? this.allowExplicit,
      zipAlbums: zipAlbums ?? this.zipAlbums,
      downloadLocation: downloadLocation ?? this.downloadLocation,
      customLocationUsesGanneFolder:
          customLocationUsesGanneFolder ?? this.customLocationUsesGanneFolder,
      flatDownloads: flatDownloads ?? this.flatDownloads,
      themeAccent: themeAccent ?? this.themeAccent,
      themeMode: themeMode ?? this.themeMode,
      useAmoled: useAmoled ?? this.useAmoled,
      enableBlur: enableBlur ?? this.enableBlur,
    );
  }

  /// Returns the quality ID based on output codec and max quality.
  String get qualityId {
    if (outputCodec == 'mp3') return '5';
    return maxQuality;
  }

  String get qualityLabel {
    switch (qualityId) {
      case '5':
        return 'MP3 320 kbps';
      case '6':
        return 'FLAC 16-Bit / 44.1 kHz';
      case '7':
        return 'FLAC 24-Bit / 96 kHz';
      case '27':
        return 'FLAC 24-Bit / 192 kHz';
      default:
        return 'Unknown';
    }
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _keyCodec = 'setting_codec';
  static const _keyQuality = 'setting_quality';
  static const _keyMetadata = 'setting_metadata';
  static const _keyExplicit = 'setting_explicit';
  static const _keyZip = 'setting_zip';
  static const _keyDownloadLocation = 'setting_download_location';
  static const _keyCustomLocationUsesGanneFolder =
      'setting_custom_location_uses_ganne_folder';
  static const _keyFlatDownloads = 'setting_flat_downloads';
  static const _keyAccent = 'setting_accent';
  static const _keyThemeMode = 'setting_theme_mode';
  static const _keyAmoled = 'setting_amoled';
  static const _keyBlur = 'setting_blur';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.readAll();
      final storedDownloadLocation = raw[_keyDownloadLocation];
      state = AppSettings(
        outputCodec: raw[_keyCodec] ?? 'flac',
        maxQuality: raw[_keyQuality] ?? '27',
        applyMetadata: raw[_keyMetadata] != 'false',
        allowExplicit: raw[_keyExplicit] != 'false',
        zipAlbums: raw[_keyZip] == 'true',
        downloadLocation:
            storedDownloadLocation == 'downloads' ||
                storedDownloadLocation == 'custom'
            ? storedDownloadLocation!
            : 'music',
        customLocationUsesGanneFolder:
            raw[_keyCustomLocationUsesGanneFolder] == 'true',
        flatDownloads: raw[_keyFlatDownloads] == 'true',
        themeAccent: raw[_keyAccent] ?? 'purple',
        themeMode: raw[_keyThemeMode] ?? 'system',
        useAmoled: raw[_keyAmoled] == 'true',
        enableBlur: raw[_keyBlur] == 'true',
      );
    } catch (e) {
      debugPrint('Settings load error: $e');
    }
  }

  Future<void> _save() async {
    final storage = ref.read(secureStorageProvider);
    await storage.writeKey(_keyCodec, state.outputCodec);
    await storage.writeKey(_keyQuality, state.maxQuality);
    await storage.writeKey(_keyMetadata, state.applyMetadata.toString());
    await storage.writeKey(_keyExplicit, state.allowExplicit.toString());
    await storage.writeKey(_keyZip, state.zipAlbums.toString());
    await storage.writeKey(_keyDownloadLocation, state.downloadLocation);
    await storage.writeKey(
      _keyCustomLocationUsesGanneFolder,
      state.customLocationUsesGanneFolder.toString(),
    );
    await storage.writeKey(_keyFlatDownloads, state.flatDownloads.toString());
    await storage.writeKey(_keyAccent, state.themeAccent);
    await storage.writeKey(_keyThemeMode, state.themeMode);
    await storage.writeKey(_keyAmoled, state.useAmoled.toString());
    await storage.writeKey(_keyBlur, state.enableBlur.toString());
  }

  void setOutputCodec(String codec) {
    state = state.copyWith(outputCodec: codec);
    _save();
  }

  void setMaxQuality(String quality) {
    state = state.copyWith(maxQuality: quality);
    _save();
  }

  void toggleMetadata(bool v) {
    state = state.copyWith(applyMetadata: v);
    _save();
  }

  void toggleExplicit(bool v) {
    state = state.copyWith(allowExplicit: v);
    _save();
  }

  void toggleZipAlbums(bool v) {
    state = state.copyWith(zipAlbums: v);
    _save();
  }

  void setDownloadLocation(String location) {
    state = state.copyWith(downloadLocation: location);
    _save();
  }

  void setCustomLocationUsesGanneFolder(bool value) {
    state = state.copyWith(customLocationUsesGanneFolder: value);
    _save();
  }

  void toggleFlatDownloads(bool v) {
    state = state.copyWith(flatDownloads: v);
    _save();
  }

  void setThemeAccent(String accent) {
    state = state.copyWith(themeAccent: accent);
    _save();
  }

  void setThemeMode(String mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void toggleAmoled(bool v) {
    state = state.copyWith(useAmoled: v);
    _save();
  }

  void toggleBlur(bool v) {
    state = state.copyWith(enableBlur: v);
    _save();
  }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  () {
    return AppSettingsNotifier();
  },
);
