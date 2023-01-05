import 'package:flutter/services.dart';

/// This is an implementation of a MethodCodec, a class that is used to encode and decode method calls and their arguments when communicating with a platform plugin via MethodChannels.
///
/// The AvesByteReceivingMethodCodec extends the built-in StandardMethodCodec to handle decoding of the method call's envelope.
class AvesByteReceivingMethodCodec extends StandardMethodCodec {
  const AvesByteReceivingMethodCodec() : super();

  @override
  dynamic decodeEnvelope(ByteData envelope) {
    // First byte is zero in success case, and non-zero otherwise.
    if (envelope.lengthInBytes == 0) {
      throw const FormatException('Expected envelope, got nothing');
    }
    final ReadBuffer buffer = ReadBuffer(envelope);
    if (buffer.getUint8() == 0) {
      return envelope.buffer.asUint8List(envelope.offsetInBytes + 1, envelope.lengthInBytes - 1);
    }

    final Object? errorCode = messageCodec.readValue(buffer);
    final Object? errorMessage = messageCodec.readValue(buffer);
    final Object? errorDetails = messageCodec.readValue(buffer);
    final String? errorStacktrace = (buffer.hasRemaining) ? messageCodec.readValue(buffer) as String? : null;
    if (errorCode is String && (errorMessage == null || errorMessage is String) && !buffer.hasRemaining) {
      throw PlatformException(code: errorCode, message: errorMessage as String?, details: errorDetails, stacktrace: errorStacktrace);
    } else {
      throw const FormatException('Invalid envelope');
    }
  }
}
