import 'dart:convert';
import 'dart:typed_data';

// adapted from Flutter `_OutputBuffer` in `/foundation/consolidate_response.dart`
/// a utility class that allows to collect a stream of binary data as it comes in, and then converts it into a single, contiguous Uint8List (an array of bytes) when closed.
///
/// This is done by keeping track of each chunk of bytes that is added, and then copying all of those chunks into a single, large byte array when close is called.
///
/// The resulting byte array can then be used for further processing or reading the data.
class OutputBuffer extends ByteConversionSinkBase {
  List<List<int>>? _chunks = <List<int>>[];
  int _contentLength = 0;
  Uint8List? _bytes;

  @override
  void add(List<int> chunk) {
    assert(_bytes == null);
    _chunks!.add(chunk);
    _contentLength += chunk.length;
  }

  @override
  void close() {
    if (_bytes != null) {
      // We've already been closed; this is a no-op
      return;
    }
    _bytes = Uint8List(_contentLength);
    int offset = 0;
    for (final List<int> chunk in _chunks!) {
      _bytes!.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    _chunks = null;
  }

  Uint8List get bytes {
    assert(_bytes != null);
    return _bytes!;
  }
}
