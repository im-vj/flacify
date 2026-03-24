import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  /// Check and request storage permission for downloads
  /// Returns true if permission is granted
  static Future<bool> requestStoragePermission() async {
    if (await Permission.storage.isGranted) {
      return true;
    }

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Check and request media location permission (for Android 10+)
  /// Required for accessing media files with location data
  static Future<bool> requestMediaLocationPermission() async {
    if (await Permission.accessMediaLocation.isGranted) {
      return true;
    }

    final status = await Permission.accessMediaLocation.request();
    return status.isGranted;
  }

  /// Check if app has all required permissions for downloads
  static Future<bool> hasDownloadPermissions() async {
    final storageGranted = await Permission.storage.isGranted;
    final mediaLocationGranted = await Permission.accessMediaLocation.isGranted;

    return storageGranted && mediaLocationGranted;
  }

  /// Open app settings to allow user to manually grant permissions
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Show a rationale dialog explaining why permissions are needed
  static Future<bool> showPermissionRationale() async {
    // Implement your own dialog logic here
    // Return true if user wants to proceed, false if they cancel
    return true;
  }
}