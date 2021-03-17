import 'dart:async';
import 'dart:ui' as ui show Codec;

import 'package:aves/services/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pedantic/pedantic.dart';

class UriImage extends ImageProvider<UriImage> {
  final String uri, mimeType;
  final int pageId, rotationDegrees, expectedContentLength;
  final bool isFlipped;
  final double scale;

  const UriImage({
    @required this.uri,
    @required this.mimeType,
    @required this.pageId,
    @required this.rotationDegrees,
    @required this.isFlipped,
    this.expectedContentLength,
    this.scale = 1.0,
  })  : assert(uri != null),
        assert(scale != null);

  @override
  Future<UriImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<UriImage>(this);
  }

  @override
  ImageStreamCompleter load(UriImage key, DecoderCallback decode) {
    final chunkEvents = StreamController<ImageChunkEvent>();

    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode, chunkEvents),
      scale: key.scale,
      chunkEvents: chunkEvents.stream,
      informationCollector: () sync* {
        yield ErrorDescription('uri=$uri, pageId=$pageId, mimeType=$mimeType');
      },
    );
  }

  Future<ui.Codec> _loadAsync(UriImage key, DecoderCallback decode, StreamController<ImageChunkEvent> chunkEvents) async {
    assert(key == this);

    try {
      final bytes = await imageFileService.getImage(
        uri,
        mimeType,
        rotationDegrees,
        isFlipped,
        pageId: pageId,
        expectedContentLength: expectedContentLength,
        onBytesReceived: (cumulative, total) {
          chunkEvents.add(ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ));
        },
      );
      if (bytes == null) {
        throw StateError('$uri ($mimeType) loading failed');
      }
      return await decode(bytes);
    } catch (error) {
      debugPrint('$runtimeType _loadAsync failed with mimeType=$mimeType, uri=$uri, error=$error');
      throw StateError('$mimeType decoding failed (page $pageId)');
    } finally {
      unawaited(chunkEvents.close());
    }
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is UriImage && other.uri == uri && other.mimeType == mimeType && other.rotationDegrees == rotationDegrees && other.isFlipped == isFlipped && other.pageId == pageId && other.scale == scale;
  }

  @override
  int get hashCode => hashValues(
        uri,
        mimeType,
        rotationDegrees,
        isFlipped,
        pageId,
        scale,
      );

  @override
  String toString() => '$runtimeType#${shortHash(this)}{uri=$uri, mimeType=$mimeType, rotationDegrees=$rotationDegrees, isFlipped=$isFlipped, pageId=$pageId, scale=$scale}';
}
