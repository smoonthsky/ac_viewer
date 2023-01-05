import 'package:aves/model/device.dart';
import 'package:aves/model/settings/enums/map_style.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves_map/aves_map.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Defines an interface for a class that checks the availability of various features and services for the application.
/// The class has three methods:
///
/// onResume(): This method is called when the application resumes from the background.
///
/// isConnected: This method returns a Future that completes with a bool indicating whether the device is currently connected to the internet or not.
///
/// canLocatePlaces: This method returns a Future that completes with a bool indicating whether the device can locate places by using the geocoder or not.
///
/// mapStyles: This method returns a list of EntryMapStyle.
abstract class AvesAvailability {
  void onResume();

  Future<bool> get isConnected;

  Future<bool> get canLocatePlaces;

  List<EntryMapStyle> get mapStyles;
}

class LiveAvesAvailability implements AvesAvailability {
  bool? _isConnected;

  LiveAvesAvailability() {
    Connectivity().onConnectivityChanged.listen(_updateConnectivityFromResult);
  }

  @override
  void onResume() => _isConnected = null;

  @override
  Future<bool> get isConnected async {
    if (_isConnected != null) return SynchronousFuture(_isConnected!);
    final result = await (Connectivity().checkConnectivity());
    _updateConnectivityFromResult(result);
    return _isConnected!;
  }

  void _updateConnectivityFromResult(ConnectivityResult result) {
    final newValue = result != ConnectivityResult.none;
    if (_isConnected != newValue) {
      _isConnected = newValue;
      debugPrint('Device is connected=$_isConnected');
    }
  }

  @override
  Future<bool> get canLocatePlaces async => device.hasGeocoder && await isConnected;

  /// uses mobileServices.mapStyles to get the available map styles for the app, and it also includes styles that don't need mobile services to be present.
  @override
  List<EntryMapStyle> get mapStyles => [
        ...mobileServices.mapStyles,
        ...EntryMapStyle.values.where((v) => !v.needMobileService),
      ];
}
