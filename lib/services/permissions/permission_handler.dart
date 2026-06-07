import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class PermissionService {
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt >= 33) {
        // Android 13+ requires specific audio/video/image permissions, or MANAGE_EXTERNAL_STORAGE
        // Since we are writing to public music directory, we might just need generic or audio.
        // But for creating files across contexts, MANAGE_EXTERNAL_STORAGE is sometimes needed if we pick custom dirs.
        var status = await Permission.manageExternalStorage.status;
        if (!status.isGranted) {
          status = await Permission.manageExternalStorage.request();
        }

        if (!status.isGranted) {
          var audioStatus = await Permission.audio.status;
          if (!audioStatus.isGranted) {
            audioStatus = await Permission.audio.request();
          }
          return audioStatus.isGranted;
        }
        return status.isGranted;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        return status.isGranted;
      }
    }
    return true; // Not Android
  }

  static Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        var status = await Permission.notification.status;
        if (!status.isGranted) {
          status = await Permission.notification.request();
        }
        return status.isGranted;
      } catch (_) {
        return false;
      }
    }
    return true; // Not mobile device
  }

  /// Check if the app is already exempted from battery optimization.
  static Future<bool> isBatteryOptimizationDisabled() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('Battery optimization check error: $e');
      return false;
    }
  }

  /// Request the user to disable battery optimization for this app.
  /// Shows the system dialog that lets the user choose to exempt the app.
  /// Returns true if the exemption was granted.
  static Future<bool> requestBatteryOptimizationExemption() async {
    if (!Platform.isAndroid) return true;
    try {
      final status = await Permission.ignoreBatteryOptimizations.status;
      if (status.isGranted) return true;

      final result = await Permission.ignoreBatteryOptimizations.request();
      return result.isGranted;
    } catch (e) {
      debugPrint('Battery optimization request error: $e');
      return false;
    }
  }
}
