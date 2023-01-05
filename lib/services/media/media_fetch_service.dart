import 'dart:async';
import 'dart:math';

import 'package:aves/model/entry.dart';
import 'package:aves/ref/mime_types.dart';
import 'package:aves/services/common/output_buffer.dart';
import 'package:aves/services/common/service_policy.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/services/media/byte_receiving_codec.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:streams_channel/streams_channel.dart';

/// an abstract class which defines methods for fetching various types of media data.
abstract class MediaFetchService {
  Future<AvesEntry?> getEntry(String uri, String? mimeType);

  Future<Uint8List> getSvg(
    String uri,
    String mimeType, {
    required int? sizeBytes,
    BytesReceivedCallback? onBytesReceived,
  });

  Future<Uint8List> getImage(
    String uri,
    String mimeType, {
    required int? rotationDegrees,
    required bool isFlipped,
    required int? pageId,
    required int? sizeBytes,
    BytesReceivedCallback? onBytesReceived,
  });

  // `rect`: region to decode, with coordinates in reference to `imageSize`
  Future<Uint8List> getRegion(
    String uri,
    String mimeType,
    int rotationDegrees,
    bool isFlipped,
    int sampleSize,
    Rectangle<int> regionRect,
    Size imageSize, {
    required int? pageId,
    required int? sizeBytes,
    Object? taskKey,
    int? priority,
  });

  Future<Uint8List> getThumbnail({
    required String uri,
    required String mimeType,
    required int rotationDegrees,
    required int? pageId,
    required bool isFlipped,
    required int? dateModifiedSecs,
    required double extent,
    Object? taskKey,
    int? priority,
  });

  Future<void> clearSizedThumbnailDiskCache();

  bool cancelRegion(Object taskKey);

  bool cancelThumbnail(Object taskKey);

  Future<T>? resumeLoading<T>(Object taskKey);
}

/// A class that implements the MediaFetchService interface.
///
/// This service allows you to fetch various data types (e.g entries, svg, images, regions, and thumbnails) from a given uri and mimetype.
///
/// It communicates with the native platform using MethodChannels, StreamsChannel and OutputBuffer.
///
/// The class defines several methods for fetching different data types such as getEntry, getSvg, getImage, getRegion, getThumbnail.
///
/// Methods like clearSizedThumbnailDiskCache, cancelRegion and cancelThumbnail provide options to clear cache, cancel fetching regions and thumbnails based on the task key provided.
///
/// resumeLoading method returns the future of the loading task.
class PlatformMediaFetchService implements MediaFetchService {
  static const _platformObject = MethodChannel('deckers.thibault/aves/media_fetch_object');
  static const _platformBytes = MethodChannel('deckers.thibault/aves/media_fetch_bytes', AvesByteReceivingMethodCodec());
  static final _byteStream = StreamsChannel('deckers.thibault/aves/media_byte_stream');
  static const double _thumbnailDefaultSize = 64.0;

  @override
  Future<AvesEntry?> getEntry(String uri, String? mimeType) async {
    try {
      final result = await _platformObject.invokeMethod('getEntry', <String, dynamic>{
        'uri': uri,
        'mimeType': mimeType,
      }) as Map;
      return AvesEntry.fromMap(result);
    } on PlatformException catch (e, stack) {
      // do not report issues with media content as it is likely an obsolete Media Store entry
      if (!uri.startsWith('content://media/')) {
        await reportService.recordError(e, stack);
      }
    }
    return null;
  }

  @override
  Future<Uint8List> getSvg(
    String uri,
    String mimeType, {
    required int? sizeBytes,
    BytesReceivedCallback? onBytesReceived,
  }) =>
      getImage(
        uri,
        mimeType,
        rotationDegrees: 0,
        isFlipped: false,
        pageId: null,
        sizeBytes: sizeBytes,
        onBytesReceived: onBytesReceived,
      );

  @override
  Future<Uint8List> getImage(
    String uri,
    String mimeType, {
    required int? rotationDegrees,
    required bool isFlipped,
    required int? pageId,
    required int? sizeBytes,
    BytesReceivedCallback? onBytesReceived,
  }) async {
    try {
      final completer = Completer<Uint8List>.sync();
      final sink = OutputBuffer();
      var bytesReceived = 0;
      _byteStream.receiveBroadcastStream(<String, dynamic>{
        'uri': uri,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'rotationDegrees': rotationDegrees ?? 0,
        'isFlipped': isFlipped,
        'pageId': pageId,
      }).listen(
        (data) {
          final chunk = data as Uint8List;
          sink.add(chunk);
          if (onBytesReceived != null) {
            bytesReceived += chunk.length;
            try {
              onBytesReceived(bytesReceived, sizeBytes);
            } catch (error, stack) {
              completer.completeError(error, stack);
              return;
            }
          }
        },
        onError: completer.completeError,
        onDone: () {
          sink.close();
          completer.complete(sink.bytes);
        },
        cancelOnError: true,
      );
      // `await` here, so that `completeError` will be caught below
      return await completer.future;
    } on PlatformException catch (e, stack) {
      if (!MimeTypes.knownMediaTypes.contains(mimeType) && MimeTypes.isVisual(mimeType)) {
        await reportService.recordError(e, stack);
      }
    }
    return Uint8List(0);
  }

  @override
  Future<Uint8List> getRegion(
    String uri,
    String mimeType,
    int rotationDegrees,
    bool isFlipped,
    int sampleSize,
    Rectangle<int> regionRect,
    Size imageSize, {
    required int? pageId,
    required int? sizeBytes,
    Object? taskKey,
    int? priority,
  }) {
    return servicePolicy.call(
      () async {
        try {
          final result = await _platformBytes.invokeMethod('getRegion', <String, dynamic>{
            'uri': uri,
            'mimeType': mimeType,
            'sizeBytes': sizeBytes,
            'pageId': pageId,
            'sampleSize': sampleSize,
            'regionX': regionRect.left,
            'regionY': regionRect.top,
            'regionWidth': regionRect.width,
            'regionHeight': regionRect.height,
            'imageWidth': imageSize.width.toInt(),
            'imageHeight': imageSize.height.toInt(),
          });
          if (result != null) return result as Uint8List;
        } on PlatformException catch (e, stack) {
          if (!MimeTypes.knownMediaTypes.contains(mimeType) && MimeTypes.isVisual(mimeType)) {
            await reportService.recordError(e, stack);
          }
        }
        return Uint8List(0);
      },
      priority: priority ?? ServiceCallPriority.getRegion,
      key: taskKey,
    );
  }

  @override
  Future<Uint8List> getThumbnail({
    required String uri,
    required String mimeType,
    required int rotationDegrees,
    required int? pageId,
    required bool isFlipped,
    required int? dateModifiedSecs,
    required double extent,
    Object? taskKey,
    int? priority,
  }) {
    return servicePolicy.call(
      () async {
        try {
          final result = await _platformBytes.invokeMethod('getThumbnail', <String, dynamic>{
            'uri': uri,
            'mimeType': mimeType,
            'dateModifiedSecs': dateModifiedSecs,
            'rotationDegrees': rotationDegrees,
            'isFlipped': isFlipped,
            'widthDip': extent,
            'heightDip': extent,
            'pageId': pageId,
            'defaultSizeDip': _thumbnailDefaultSize,
            'quality': 100,
          });
          if (result != null) return result as Uint8List;
        } on PlatformException catch (e, stack) {
          if (!MimeTypes.knownMediaTypes.contains(mimeType) && MimeTypes.isVisual(mimeType)) {
            await reportService.recordError(e, stack);
          }
        }
        return Uint8List(0);
      },
      priority: priority ?? (extent == 0 ? ServiceCallPriority.getFastThumbnail : ServiceCallPriority.getSizedThumbnail),
      key: taskKey,
    );
  }

  @override
  Future<void> clearSizedThumbnailDiskCache() async {
    try {
      return _platformObject.invokeMethod('clearSizedThumbnailDiskCache');
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  @override
  bool cancelRegion(Object taskKey) => servicePolicy.pause(taskKey, [ServiceCallPriority.getRegion]);

  @override
  bool cancelThumbnail(Object taskKey) => servicePolicy.pause(taskKey, [ServiceCallPriority.getFastThumbnail, ServiceCallPriority.getSizedThumbnail]);

  @override
  Future<T>? resumeLoading<T>(Object taskKey) => servicePolicy.resume<T>(taskKey);
}
