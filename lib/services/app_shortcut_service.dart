import 'dart:typed_data';

import 'package:aves/model/entry.dart';
import 'package:aves/model/filters/filters.dart';
import 'package:aves/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppShortcutService {
  static const platform = MethodChannel('deckers.thibault/aves/shortcut');

  // this ability will not change over the lifetime of the app
  static bool? _canPin;

  static Future<bool> canPin() async {
    if (_canPin != null) {
      return SynchronousFuture(_canPin!);
    }

    try {
      final result = await platform.invokeMethod('canPin');
      if (result != null) {
        _canPin = result;
        return result;
      }
    } on PlatformException catch (e) {
      await reportService.recordChannelError('canPin', e);
    }
    return false;
  }

  static Future<void> pin(String label, AvesEntry? entry, Set<CollectionFilter> filters) async {
    Uint8List? iconBytes;
    if (entry != null) {
      final size = entry.isVideo ? 0.0 : 256.0;
      iconBytes = await imageFileService.getThumbnail(
        uri: entry.uri,
        mimeType: entry.mimeType,
        pageId: entry.pageId,
        rotationDegrees: entry.rotationDegrees,
        isFlipped: entry.isFlipped,
        dateModifiedSecs: entry.dateModifiedSecs,
        extent: size,
      );
    }
    try {
      await platform.invokeMethod('pin', <String, dynamic>{
        'label': label,
        'iconBytes': iconBytes,
        'filters': filters.map((filter) => filter.toJson()).toList(),
      });
    } on PlatformException catch (e) {
      await reportService.recordChannelError('pin', e);
    }
  }
}
