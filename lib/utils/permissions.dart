import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class PermissionUtils {
  static const platform = MethodChannel('com.example.wifi_file_transfer/permissions');

  // Required permissions for WiFi Direct file transfer
  static final List<Permission> requiredPermissions = [
    Permission.location,
    Permission.locationWhenInUse,
    Permission.nearbyWifiDevices,
    Permission.storage,
    Permission.notification,
  ];

  // Check if all permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    Map<Permission, PermissionStatus> statuses = await requiredPermissions.request();

    return statuses.values.every((status) =>
      status == PermissionStatus.granted || status == PermissionStatus.limited
    );
  }

  // Request all required permissions
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    return await requiredPermissions.request();
  }

  // Check specific permission
  static Future<bool> isPermissionGranted(Permission permission) async {
    final status = await permission.status;
    return status == PermissionStatus.granted || status == PermissionStatus.limited;
  }

  // Request specific permission
  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    return status == PermissionStatus.granted || status == PermissionStatus.limited;
  }

  // Check location permission (required for WiFi Direct)
  static Future<bool> checkLocationPermission() async {
    bool locationGranted = await isPermissionGranted(Permission.location);
    if (!locationGranted) {
      locationGranted = await requestPermission(Permission.location);
    }

    return locationGranted;
  }

  // Check storage permission
  static Future<bool> checkStoragePermission() async {
    bool storageGranted = await isPermissionGranted(Permission.storage);
    if (!storageGranted) {
      storageGranted = await requestPermission(Permission.storage);
    }

    return storageGranted;
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  // Get permission status description
  static String getPermissionStatusDescription(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.provisional:
        return 'Provisional';
    }
  }

  // Check if permission should show rationale
  static Future<bool> shouldShowPermissionRationale(Permission permission) async {
    return await permission.shouldShowRequestRationale;
  }

  // Get denied permissions list
  static Future<List<Permission>> getDeniedPermissions() async {
    final deniedPermissions = <Permission>[];

    for (final permission in requiredPermissions) {
      if (!await isPermissionGranted(permission)) {
        deniedPermissions.add(permission);
      }
    }

    return deniedPermissions;
  }

  // Request permissions with result callback
  static Future<void> requestPermissionsWithCallback(
    Function(bool allGranted, Map<Permission, PermissionStatus> results) callback
  ) async {
    final results = await requestAllPermissions();
    final allGranted = results.values.every((status) =>
      status == PermissionStatus.granted || status == PermissionStatus.limited
    );

    callback(allGranted, results);
  }
}