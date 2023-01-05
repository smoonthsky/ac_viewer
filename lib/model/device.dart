import 'package:aves/services/common/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

final Device device = Device._private();

class Device {
  late final String _userAgent;
  late final bool _canGrantDirectoryAccess, _canPinShortcut, _canPrint, _canRenderFlagEmojis, _canRequestManageMedia, _canSetLockScreenWallpaper;
  late final bool _hasGeocoder, _isDynamicColorAvailable, _isTelevision, _showPinShortcutFeedback, _supportEdgeToEdgeUIMode;

  /// A sample result of _userAgent could be a string in the following format:
  ///
  /// 'com.example.app/1.0.0'
  ///
  /// where "com.example.app" is the package name of the app, and "1.0.0" is the version of the app.
  ///
  /// It is created by combining package name and version number, obtained by PackageInfo.fromPlatform() method.
  ///
  /// Please keep in mind that the actual value of _userAgent would depend on the package name and version of the app that the code is running on.
  String get userAgent => _userAgent;

  bool get canGrantDirectoryAccess => _canGrantDirectoryAccess;

  bool get canPinShortcut => _canPinShortcut;

  bool get canPrint => _canPrint;

  bool get canRenderFlagEmojis => _canRenderFlagEmojis;

  bool get canRequestManageMedia => _canRequestManageMedia;

  bool get canSetLockScreenWallpaper => _canSetLockScreenWallpaper;

  bool get hasGeocoder => _hasGeocoder;

  bool get isDynamicColorAvailable => _isDynamicColorAvailable;

  bool get isReadOnly => _isTelevision;

  bool get isTelevision => _isTelevision;

  bool get showPinShortcutFeedback => _showPinShortcutFeedback;

  bool get supportEdgeToEdgeUIMode => _supportEdgeToEdgeUIMode;

  Device._private();

  Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _userAgent = '${packageInfo.packageName}/${packageInfo.version}';

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    _isTelevision = androidInfo.systemFeatures.contains('android.software.leanback');

    final capabilities = await deviceService.getCapabilities();
    _canGrantDirectoryAccess = capabilities['canGrantDirectoryAccess'] ?? false;
    _canPinShortcut = capabilities['canPinShortcut'] ?? false;
    _canPrint = capabilities['canPrint'] ?? false;
    _canRenderFlagEmojis = capabilities['canRenderFlagEmojis'] ?? false;
    _canRequestManageMedia = capabilities['canRequestManageMedia'] ?? false;
    _canSetLockScreenWallpaper = capabilities['canSetLockScreenWallpaper'] ?? false;
    _hasGeocoder = capabilities['hasGeocoder'] ?? false;
    _isDynamicColorAvailable = capabilities['isDynamicColorAvailable'] ?? false;
    _showPinShortcutFeedback = capabilities['showPinShortcutFeedback'] ?? false;
    _supportEdgeToEdgeUIMode = capabilities['supportEdgeToEdgeUIMode'] ?? false;
  }
}

// androidInfo is an instance of AndroidDeviceInfo class, which contains various information about the device and the Android version it is running.
// The fields of this class contains information like device model, androidId, manufacturer, version, etc.
// A sample value of this object for an androidInfo might look like this:
// AndroidDeviceInfo(
//   version: AndroidVersion(
//     sdkInt: 29,
//     release: '10',
//     codename: 'Q',
//   ),
//   model: 'Pixel 4',
//   product: 'q3a',
//   manufacturer: 'Google',
//   androidId: 'dbc914b8f9ec48d9',
//   fingerprint: 'google/redfin/redfin:11/RP1A.200720.009/6720564:user/release-keys',
//   board: 'redfin',
//   bootloader: 'Unknown',
//   brand: 'google',
//   device: 'redfin',
//   display: 'RP1A.200720.009',
//   hardware: 'q3a',
//   host: '',
//   id: 'RP1A.200720.009',
//   isPhysicalDevice: true,
//   tags: '',
//   type: 'user',
//   user: '',
//   systemFeatures: [
//     'android.hardware.audio.output',
//     'android.hardware.camera',
//     'android.hardware.camera.any',
//     'android.hardware.camera.front',
//     'android.hardware.faketouch',
//     'android.hardware.location',
//     'android.hardware.screen.portrait',
//     'android.hardware.telephony',
//     'android.hardware.wifi',
//   ],
// )