import 'package:aves/services/common/services.dart';
import 'package:flutter/services.dart';

class WidgetService {
  static const _configureChannel = MethodChannel('deckers.thibault/aves/widget_configure');
  static const _updateChannel = MethodChannel('deckers.thibault/aves/widget_update');
  static const _homeScreenWidgetChannel = MethodChannel('anonymity.ac.viewer/aves/home_screen_widget');

  static Future<bool> configure() async {
    try {
      await _configureChannel.invokeMethod('configure');
      return true;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return false;
  }

  static Future<bool> update(int widgetId) async {
    try {
      await _updateChannel.invokeMethod('update', <String, dynamic>{
        'widgetId': widgetId,
      });
      return true;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return false;
  }

  static Future<List<int>> getHomeScreenWidgetIds() async {
    try {
      final ids = await _homeScreenWidgetChannel.invokeMethod('getHomeScreenWidgetIds');
      return ids.cast<int>();
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return [];
  }

}
