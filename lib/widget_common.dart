import 'dart:async';

import 'package:aves/app_flavor.dart';
import 'package:aves/model/entry.dart';
import 'package:aves/model/settings/enums/enums.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/model/source/collection_lens.dart';
import 'package:aves/model/source/media_store_source.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/home_widget.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter/foundation.dart';

import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';


const _widgetDrawChannel = MethodChannel('deckers.thibault/aves/widget_draw');

void widgetMainCommon(AppFlavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  initPlatformServices();
  await settings.init(monitorPlatformSettings: false);

  _widgetDrawChannel.setMethodCallHandler((call) async {
    // widget settings may be modified in a different process after channel setup
    await settings.reload();

    switch (call.method) {
      case 'drawWidget':
        return _drawWidget(call.arguments);
      case 'getWidgetUpdateInterval':
        // debugPrint('call by HomeWidgetProvider scheduleNextUpdate ${call.method} ');
        return _getWidgetUpdateInterval(call.arguments);
      default:
        throw PlatformException(code: 'not-implemented', message: 'failed to handle method=${call.method}');
    }
  });
}

/* AC Viewer : Widget update use AlarmManager in Kotlin side  */
Future<int> _getWidgetUpdateInterval(dynamic arguments) async {
  final widgetId = arguments as int;
  // debugPrint('get widgetId from HomeWidgetProvider scheduleNextUpdate ${widgetId} ');
  int widgetUpdateInterval =settings.getWidgetUpdateInterval(widgetId);
  // debugPrint('return  widgetUpdateInterval to HomeWidgetProvider scheduleNextUpdate ${widgetUpdateInterval} ');
  return widgetUpdateInterval;
}

Future<void> _setWallpaperFromWidget(int widgetId,AvesEntry? entry) async{
  if (entry != null) {
    WidgetWallpaperLocation location = settings.getWidgetWallpaperLocation(
        widgetId);
    switch (location) {
      case WidgetWallpaperLocation.none:
        break;
      case WidgetWallpaperLocation.homeScreen:
        await WallpaperManager.setWallpaperFromFile(
            entry.toMap()['path'], WallpaperManager.HOME_SCREEN);
        break;
      case WidgetWallpaperLocation.lockScreen:
        await WallpaperManager.setWallpaperFromFile(
            entry.toMap()['path'], WallpaperManager.LOCK_SCREEN);
        break;
      case WidgetWallpaperLocation.bothScreen:
        await WallpaperManager.setWallpaperFromFile(
            entry.toMap()['path'], WallpaperManager.BOTH_SCREEN);
        break; //provide image path
    }
  }
}
/* AC Viewer : Widget set Wallpaper end */

Future<Uint8List> _drawWidget(dynamic args) async {
  final widgetId = args['widgetId'] as int;
  final widthPx = args['widthPx'] as int;
  final heightPx = args['heightPx'] as int;
  final devicePixelRatio = args['devicePixelRatio'] as double;
  final drawEntryImage = args['drawEntryImage'] as bool;
  final reuseEntry = args['reuseEntry'] as bool;

  final entry = drawEntryImage ? await _getWidgetEntry(widgetId, reuseEntry) : null;

  await _setWallpaperFromWidget(widgetId,entry);

  final painter = HomeWidgetPainter(
    entry: entry,
    devicePixelRatio: devicePixelRatio,
  );
  return painter.drawWidget(
    widthPx: widthPx,
    heightPx: heightPx,
    outline: settings.getWidgetOutline(widgetId),
    shape: settings.getWidgetShape(widgetId),
  );
}

Future<AvesEntry?> _getWidgetEntry(int widgetId, bool reuseEntry) async {
  final uri = reuseEntry ? settings.getWidgetUri(widgetId) : null;
  if (uri != null) {
    final entry = await mediaFetchService.getEntry(uri, null);
    if (entry != null) return entry;
  }

  await androidFileUtils.init();

  final filters = settings.getWidgetCollectionFilters(widgetId);
  final source = MediaStoreSource();
  final readyCompleter = Completer();
  source.stateNotifier.addListener(() {
    if (source.isReady) {
      readyCompleter.complete();
    }
  });
  await source.init(canAnalyze: false);
  await readyCompleter.future;

  final entries = CollectionLens(source: source, filters: filters).sortedEntries;
  switch (settings.getWidgetDisplayedItem(widgetId)) {
    case WidgetDisplayedItem.random:
      entries.shuffle();
      break;
    case WidgetDisplayedItem.mostRecent:
      entries.sort(AvesEntry.compareByDate);
      break;
  }
  final entry = entries.firstOrNull;
  if (entry != null) {
    settings.setWidgetUri(widgetId, entry.uri);
  }
  return entry;
}
