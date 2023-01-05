import 'dart:async';

import 'package:aves/model/entry.dart';
import 'package:aves/model/metadata/date_modifier.dart';
import 'package:aves/model/metadata/enums/enums.dart';
import 'package:aves/model/metadata/enums/metadata_type.dart';
import 'package:aves/model/metadata/fields.dart';
import 'package:aves/services/common/services.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';

/// An abstract class MetadataEditService that defines a set of methods for editing metadata of a media file.
///
/// This class has several methods that allow you to rotate, flip, edit the date, edit metadata, remove trailer video and remove certain types of metadata from a media file.
///
/// All these methods are implemented by PlatformMetadataEditService. This class uses the MethodChannel to call the corresponding native code to perform the operations. The native code is implemented by a specific platform, such as Android or iOS, and is associated with the channel name deckers.thibault/aves/metadata_edit. If there is an exception, it is caught, and the error is reported via the reportService object.
abstract class MetadataEditService {
  Future<Map<String, dynamic>> rotate(AvesEntry entry, {required bool clockwise});

  Future<Map<String, dynamic>> flip(AvesEntry entry);

  Future<Map<String, dynamic>> editExifDate(AvesEntry entry, DateModifier modifier);

  Future<Map<String, dynamic>> editMetadata(AvesEntry entry, Map<MetadataType, dynamic> modifier, {bool autoCorrectTrailerOffset = true});

  Future<Map<String, dynamic>> removeTrailerVideo(AvesEntry entry);

  Future<Map<String, dynamic>> removeTypes(AvesEntry entry, Set<MetadataType> types);
}

/// PlatformMetadataEditService is a concrete implementation of the MetadataEditService abstract class.
///
/// It uses a MethodChannel to communicate with the native platform (Android/iOS) to perform operations related to editing metadata of media files.
/// The methods include:
///
/// rotate - rotates the given media file by clockwise or anticlockwise
///
/// flip - flips the given media file
///
/// editExifDate - edit the exif date of the given media file
///
/// editMetadata - edit the metadata of the given media file
///
/// removeTrailerVideo - remove the trailer video of the given media file
///
/// removeTypes - remove metadata types of the given media file.
///
/// Each of these methods return a future that completes with a Map containing the response data from the native platform.
class PlatformMetadataEditService implements MetadataEditService {
  static const _platform = MethodChannel('deckers.thibault/aves/metadata_edit');

  @override
  Future<Map<String, dynamic>> rotate(AvesEntry entry, {required bool clockwise}) async {
    try {
      // returns map with: 'rotationDegrees' 'isFlipped'
      final result = await _platform.invokeMethod('rotate', <String, dynamic>{
        'entry': entry.toPlatformEntryMap(),
        'clockwise': clockwise,
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> flip(AvesEntry entry) async {
    try {
      // returns map with: 'rotationDegrees' 'isFlipped'
      final result = await _platform.invokeMethod('flip', <String, dynamic>{
        'entry': entry.toPlatformEntryMap(),
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> editExifDate(AvesEntry entry, DateModifier modifier) async {
    try {
      final result = await _platform.invokeMethod('editDate', <String, dynamic>{
        'entry': entry.toPlatformEntryMap(),
        'dateMillis': modifier.setDateTime?.millisecondsSinceEpoch,
        'shiftMinutes': modifier.shiftMinutes,
        'fields': modifier.fields.where((v) => v.type == MetadataType.exif).map((v) => v.toPlatform).whereNotNull().toList(),
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> editMetadata(
    AvesEntry entry,
    Map<MetadataType, dynamic> metadata, {
    bool autoCorrectTrailerOffset = true,
  }) async {
    try {
      final result = await _platform.invokeMethod('editMetadata', <String, dynamic>{
        'entry': entry.toPlatformEntryMap(),
        'metadata': metadata.map((type, value) => MapEntry(type.toPlatform, value)),
        'autoCorrectTrailerOffset': autoCorrectTrailerOffset,
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> removeTrailerVideo(AvesEntry entry) async {
    try {
      final result = await _platform.invokeMethod('removeTrailerVideo', <String, dynamic>{
        'entry': entry.toPlatformEntryMap(),
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }

  @override
  Future<Map<String, dynamic>> removeTypes(AvesEntry entry, Set<MetadataType> types) async {
    try {
      final result = await _platform.invokeMethod('removeTypes', <String, dynamic>{
        'entry': entry.toPlatformEntryMap(),
        'types': types.map((v) => v.toPlatform).toList(),
      });
      if (result != null) return (result as Map).cast<String, dynamic>();
    } on PlatformException catch (e, stack) {
      if (!entry.isMissingAtPath) {
        await reportService.recordError(e, stack);
      }
    }
    return {};
  }
}
