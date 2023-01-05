import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// adapted from Flutter `EventChannel` in `/services/platform_channel.dart`
/// to use an `OptionalMethodChannel` when subscribing to events
class OptionalEventChannel extends EventChannel {
  const OptionalEventChannel(super.name, [super.codec = const StandardMethodCodec(), super.binaryMessenger]);

  @override
  Stream<dynamic> receiveBroadcastStream([dynamic arguments]) {
    final MethodChannel methodChannel = OptionalMethodChannel(name, codec);
    late StreamController<dynamic> controller;
    controller = StreamController<dynamic>.broadcast(onListen: () async {
      binaryMessenger.setMessageHandler(name, (reply) async {
        if (reply == null) {
          await controller.close();
        } else {
          try {
            controller.add(codec.decodeEnvelope(reply));
          } on PlatformException catch (e) {
            controller.addError(e);
          }
        }
        return null;
      });
      try {
        await methodChannel.invokeMethod<void>('listen', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: ErrorDescription('while activating platform stream on channel $name'),
        ));
      }
    }, onCancel: () async {
      binaryMessenger.setMessageHandler(name, null);
      try {
        await methodChannel.invokeMethod<void>('cancel', arguments);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'services library',
          context: ErrorDescription('while de-activating platform stream on channel $name'),
        ));
      }
    });
    return controller.stream;
  }
}
/// receiveBroadcastStream is a method that creates and returns a broadcast stream.
///
/// When the stream is listened to, it activates the underlying platform stream on the given channel, and starts delivering events from the platform to the Dart stream. The stream is implemented using a StreamController which broadcasts events to all listeners.
///
/// When receiveBroadcastStream is called, it creates a MethodChannel with the given name and codec.
///
/// It also sets up a message handler on the binary messenger to handle incoming events from the platform.
///
/// The message handler listens for incoming events on the channel, and when it receives one, it decodes it using the codec, and sends the resulting data to the stream controller's stream.
///
/// If the received message is null, it closes the stream controller.
///
/// The onListen callback is called when the stream is listened to, which triggers the underlying method channel to invoke the listen method to start listening to the platform events.
///
/// The onCancel callback is called when the stream is closed, which triggers the underlying method channel to invoke the cancel method to stop listening to the platform events.
///
/// It is built on top of StandardMethodCodec which is a codec that is able to encode and decode the standard Flutter method calls and method call results.
///
/// It can handle values of types null, bool, int, double, String, Uint8List, and Lists and Maps of those types.
///