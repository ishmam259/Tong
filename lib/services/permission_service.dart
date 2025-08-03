import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:flutter/foundation.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Request all necessary permissions for Bluetooth and WiFi
  Future<bool> requestAllPermissions() async {
    try {
      final permissions = <ph.Permission>[
        ph.Permission.bluetooth,
        ph.Permission.bluetoothScan,
        ph.Permission.bluetoothConnect,
        ph.Permission.bluetoothAdvertise,
        ph.Permission.locationWhenInUse,
        ph.Permission.nearbyWifiDevices,
      ];

      final statuses = await permissions.request();

      bool allGranted = true;
      for (final permission in permissions) {
        final status = statuses[permission];
        if (status != ph.PermissionStatus.granted) {
          allGranted = false;
          if (kDebugMode) {
            print('❌ Permission denied: $permission - $status');
          }
        }
      }

      if (kDebugMode) {
        print(
          allGranted
              ? '✅ All permissions granted'
              : '❌ Some permissions denied',
        );
      }

      return allGranted;
    } catch (e) {
      if (kDebugMode) print('❌ Error requesting permissions: $e');
      return false;
    }
  }

  /// Check if Bluetooth permissions are granted
  Future<bool> hasBluetoothPermissions() async {
    final bluetoothScan = await ph.Permission.bluetoothScan.status;
    final bluetoothConnect = await ph.Permission.bluetoothConnect.status;
    final location = await ph.Permission.locationWhenInUse.status;

    return bluetoothScan.isGranted &&
        bluetoothConnect.isGranted &&
        location.isGranted;
  }

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await ph.Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  /// Request specific permission
  Future<bool> requestPermission(ph.Permission permission) async {
    final status = await permission.request();
    return status.isGranted;
  }

  /// Open app settings if permissions are permanently denied
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }
}
