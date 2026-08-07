import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
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

  static Future<bool> requestLegacyStoragePermission() async {
    if (!Platform.isAndroid) return true;
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) status = await Permission.storage.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }
}
