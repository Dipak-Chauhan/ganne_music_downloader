import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../secure_storage/secure_storage.dart';
import 'service_providers.dart';

class AppSettings {
  final String outputCodec;     // 'flac' or 'mp3'
  final String maxQuality;      // '5', '6', '7', '27'
  final bool applyMetadata;
  final bool allowExplicit;
  final bool zipAlbums;
  final String themeAccent;     // 'purple', 'ocean', 'emerald', 'crimson', 'sunset', 'sakura', 'dynamic'

  const AppSettings({
    this.outputCodec = 'flac',
    this.maxQuality = '27',
    this.applyMetadata = true,
    this.allowExplicit = true,
    this.zipAlbums = false,
    this.themeAccent = 'purple',
  });

  AppSettings copyWith({
    String? outputCodec,
    String? maxQuality,
    bool? applyMetadata,
    bool? allowExplicit,
    bool? zipAlbums,
    String? themeAccent,
  }) {
    return AppSettings(
      outputCodec: outputCodec ?? this.outputCodec,
      maxQuality: maxQuality ?? this.maxQuality,
      applyMetadata: applyMetadata ?? this.applyMetadata,
      allowExplicit: allowExplicit ?? this.allowExplicit,
      zipAlbums: zipAlbums ?? this.zipAlbums,
      themeAccent: themeAccent ?? this.themeAccent,
    );
  }

  /// Returns the quality ID based on output codec and max quality.
  String get qualityId {
    if (outputCodec == 'mp3') return '5';
    return maxQuality;
  }

  String get qualityLabel {
    switch (qualityId) {
      case '5':  return 'MP3 320 kbps';
      case '6':  return 'FLAC 16-Bit / 44.1 kHz';
      case '7':  return 'FLAC 24-Bit / 96 kHz';
      case '27': return 'FLAC 24-Bit / 192 kHz';
      default:   return 'Unknown';
    }
  }
}

class AppSettingsNotifier extends Notifier<AppSettings> {
  static const _keyCodec = 'setting_codec';
  static const _keyQuality = 'setting_quality';
  static const _keyMetadata = 'setting_metadata';
  static const _keyExplicit = 'setting_explicit';
  static const _keyZip = 'setting_zip';
  static const _keyAccent = 'setting_accent';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    try {
      final storage = ref.read(secureStorageProvider);
      final raw = await storage.readAll();
      state = AppSettings(
        outputCodec: raw[_keyCodec] ?? 'flac',
        maxQuality: raw[_keyQuality] ?? '27',
        applyMetadata: raw[_keyMetadata] != 'false',
        allowExplicit: raw[_keyExplicit] != 'false',
        zipAlbums: raw[_keyZip] == 'true',
        themeAccent: raw[_keyAccent] ?? 'purple',
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
    await storage.writeKey(_keyAccent, state.themeAccent);
  }

  void setOutputCodec(String codec) { state = state.copyWith(outputCodec: codec); _save(); }
  void setMaxQuality(String quality) { state = state.copyWith(maxQuality: quality); _save(); }
  void toggleMetadata(bool v) { state = state.copyWith(applyMetadata: v); _save(); }
  void toggleExplicit(bool v) { state = state.copyWith(allowExplicit: v); _save(); }
  void toggleZipAlbums(bool v) { state = state.copyWith(zipAlbums: v); _save(); }
  void setThemeAccent(String accent) { state = state.copyWith(themeAccent: accent); _save(); }
}

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(() {
  return AppSettingsNotifier();
});
