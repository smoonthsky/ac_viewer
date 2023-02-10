import 'package:aves/model/entry.dart';
import 'package:aves/services/common/services.dart';
import 'package:aves/utils/constants.dart';
import 'package:flutter/services.dart';

abstract class EmbeddedDataService {
  Future<List<Uint8List>> getExifThumbnails(AvesEntry entry);

  Future<Map> extractMotionPhotoImage(AvesEntry entry);

  Future<Map> extractMotionPhotoVideo(AvesEntry entry);

  Future<Map> extractVideoEmbeddedPicture(AvesEntry entry);

  Future<Map> extractXmpDataProp(AvesEntry entry, List<dynamic>? props, String? propMimeType);
}

class PlatformEmbeddedDataService implements EmbeddedDataService {
  static const _platform = MethodChannel('deckers.thibault/aves/embedded');

  @override
  Future<List<Uint8List>> getExifThumbnails(AvesEntry entry) async {
    try {
      final result = await _platform.invokeMethod('getExifThumbnails', <String, dynamic>{
        'mimeType': entry.mimeType,
        'uri': entry.uri,
        'sizeBytes': entry.sizeBytes,
      });
      if (result != null) return (result as List).cast<Uint8List>();
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return [];
  }

  @override
  Future<Map> extractMotionPhotoImage(AvesEntry entry) async {
    try {
      final result = await _platform.invokeMethod('extractMotionPhotoImage', <String, dynamic>{
        'mimeType': entry.mimeType,
        'uri': entry.uri,
        'sizeBytes': entry.sizeBytes,
        'displayName': ['${entry.bestTitle}', 'Image'].join(Constants.separator),
      });
      if (result != null) return result as Map;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return {};
  }

  @override
  Future<Map> extractMotionPhotoVideo(AvesEntry entry) async {
    try {
      final result = await _platform.invokeMethod('extractMotionPhotoVideo', <String, dynamic>{
        'mimeType': entry.mimeType,
        'uri': entry.uri,
        'sizeBytes': entry.sizeBytes,
        'displayName': ['${entry.bestTitle}', 'Video'].join(Constants.separator),
      });
      if (result != null) return result as Map;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return {};
  }

  @override
  Future<Map> extractVideoEmbeddedPicture(AvesEntry entry) async {
    try {
      final result = await _platform.invokeMethod('extractVideoEmbeddedPicture', <String, dynamic>{
        'uri': entry.uri,
        'displayName': ['${entry.bestTitle}', 'Cover'].join(Constants.separator),
      });
      if (result != null) return result as Map;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return {};
  }

  @override
  Future<Map> extractXmpDataProp(AvesEntry entry, List<dynamic>? props, String? propMimeType) async {
    try {
      final result = await _platform.invokeMethod('extractXmpDataProp', <String, dynamic>{
        'mimeType': entry.mimeType,
        'uri': entry.uri,
        'sizeBytes': entry.sizeBytes,
        'displayName': ['${entry.bestTitle}', '$props'].join(Constants.separator),
        'propPath': props,
        'propMimeType': propMimeType,
      });
      if (result != null) return result as Map;
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
    return {};
  }
}
