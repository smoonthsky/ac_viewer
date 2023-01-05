import 'dart:async';

import 'package:aves/services/common/services.dart';
import 'package:aves/widgets/viewer/video/controller.dart';
import 'package:flutter/services.dart';

/// MediaSessionService is an abstract class for a service that can control the state of media sessions for a given AvesVideoController instance.
///
/// A media session is a transient "session" of media playback that can be initiated, updated, and released.
///
/// The update method is used to provide the service with an AvesVideoController instance to control the session.
///
/// The release method is used to release the media session and cleanup the resources associated with it.
///
/// This is typically used when the playback is completed or the user navigates away from the page.
abstract class MediaSessionService {
  Future<void> update(AvesVideoController controller);

  Future<void> release(String uri);
}

/// PlatformMediaSessionService is a class that implements the MediaSessionService abstract class.
///
/// It is used for interacting with the device's media session, which manages the playback of audio and video on the device.
///
/// `update(AvesVideoController controller)` is used to update the media session with the details of the current video playback, such as the title, duration, state, position, and playback speed.
///
/// `release(String uri)` is used to release the media session and clean up resources when playback is complete or when the user navigates away from the video.
///
/// It also has some methods that uses MethodChannels(_platformObject) for invoking platform-specific methods for interacting with the media session.
class PlatformMediaSessionService implements MediaSessionService {
  static const _platformObject = MethodChannel('deckers.thibault/aves/media_session');

  @override
  Future<void> update(AvesVideoController controller) async {
    final entry = controller.entry;
    try {
      await _platformObject.invokeMethod('update', <String, dynamic>{
        'uri': entry.uri,
        'title': entry.bestTitle,
        'durationMillis': controller.duration,
        'state': _toPlatformState(controller.status),
        'positionMillis': controller.currentPosition,
        'playbackSpeed': controller.speed,
      });
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  @override
  Future<void> release(String uri) async {
    try {
      await _platformObject.invokeMethod('release', <String, dynamic>{
        'uri': uri,
      });
    } on PlatformException catch (e, stack) {
      await reportService.recordError(e, stack);
    }
  }

  String _toPlatformState(VideoStatus status) {
    switch (status) {
      case VideoStatus.paused:
        return 'paused';
      case VideoStatus.playing:
        return 'playing';
      case VideoStatus.idle:
      case VideoStatus.initialized:
      case VideoStatus.completed:
      case VideoStatus.error:
        return 'stopped';
    }
  }
}
