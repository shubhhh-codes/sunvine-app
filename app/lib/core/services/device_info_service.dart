import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Metadata representing the current physical or virtual client device.
class DeviceMetadata {
  final String deviceId;
  final String deviceName;
  final String appVersion;
  final String platform;

  const DeviceMetadata({
    required this.deviceId,
    required this.deviceName,
    required this.appVersion,
    required this.platform,
  });

  Map<String, String> toMap() => {
        'deviceId': deviceId,
        'deviceName': deviceName,
        'appVersion': appVersion,
        'platform': platform,
      };
}

/// Service responsible for gathering device identity and hardware specifications.
class DeviceInfoService {
  final DeviceInfoPlugin _deviceInfo;
  DeviceMetadata? _cachedMetadata;

  DeviceInfoService({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  /// Retrieves or lazily loads device metadata.
  Future<DeviceMetadata> getMetadata() async {
    if (_cachedMetadata != null) return _cachedMetadata!;

    String deviceId = 'client-generic';
    String deviceName = 'Client Device';
    String appVersion = '1.0.0';
    String platform = 'unknown';

    if (kIsWeb) {
      platform = 'web';
      deviceId = 'web-browser';
      deviceName = 'Web Browser';
      try {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceName = '${webInfo.browserName.name} on ${webInfo.platform ?? "Desktop"}';
      } catch (_) {}
    } else {
      platform = io.Platform.operatingSystem;
      try {
        if (io.Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          deviceId = androidInfo.id;
          deviceName = '${androidInfo.brand} ${androidInfo.model}'.trim();
        } else if (io.Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          deviceId = iosInfo.identifierForVendor ?? 'ios-generic';
          deviceName = iosInfo.utsname.machine;
        } else if (io.Platform.isWindows) {
          final winInfo = await _deviceInfo.windowsInfo;
          deviceId = winInfo.deviceId;
          deviceName = winInfo.computerName;
        }
      } catch (_) {}
    }

    try {
      final pkg = await PackageInfo.fromPlatform();
      appVersion = pkg.version;
    } catch (_) {}

    _cachedMetadata = DeviceMetadata(
      deviceId: deviceId,
      deviceName: deviceName,
      appVersion: appVersion,
      platform: platform,
    );

    return _cachedMetadata!;
  }

  /// Convenience getter for the unique device identifier.
  Future<String> getDeviceId() async {
    final meta = await getMetadata();
    return meta.deviceId;
  }
}
